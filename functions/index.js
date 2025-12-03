const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {GoogleGenAI} = require("@google/genai");

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const generationConfig = {
  responseMimeType: "application/json",

  responseSchema: {
    type: "array",
    description: "A list of all valid medications found in the prescription image.",

    items: {
      type: "object",
      description: "A single medication entry with its dosage schedule.",
      properties: {
        medicine_name: {
          type: "string",
          description: "The exact name of the medication (e.g., 'Metoprolol Succinate').",
        },
        dosages: {
          type: "object",
          description: "The specific dosage schedule for the medication.",
          properties: {
            start_date: {
              type: "string",
              format: "date",
              description: "The date the medication starts, using the format YYYY-MM-DD. Use the current date if not specified in the image.",
            },
            days: {
              type: "integer",
              description: "The total duration of the prescription in number of days.",
            },
            timings: {
              type: "array",
              description: "A list of required daily dosage times/contexts.",
              items: {
                type: "object",
                properties: {
                  context: {
                    type: "string",
                    enum: ["Morning", "Afternoon", "Evening", "Night"],
                    description: "The time of day for the dose (one of the enumerated options).",
                  },
                },
                required: ["context"],
              },
            },
          },
          required: ["start_date", "days", "timings"],
        },
      },
      required: ["medicine_name", "dosages"],
    },
  },
};

exports.generateContentWithGemini = onCall(
    {enforceAppCheck: true, secrets: ["GEMINI_API_KEY"]},
    async (request) => {
      if (!request.auth || !request.auth.uid) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called by an authenticated user.",
        );
      }

      const userId = request.auth.uid;
      const {image, prompt} = request.data;

      try {
        const genai = new GoogleGenAI({apiKey: GEMINI_API_KEY});
        const imagePart = {
          inlineData: {
            data: image,
            mimeType: "image/jpeg",
          },
        };
        const response = await genai.models.generateContent({
          model: "gemini-2.5-flash",
          contents: [prompt, imagePart],
          config: generationConfig,
        });

        return {result: response.text};
      } catch (error) {
        console.error("Gemini call failed for user", userId, error);
        throw new HttpsError(
            "internal",
            "An error occurred while generating content.",
            error.message,
        );
      }
    },
);
