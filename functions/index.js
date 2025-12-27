const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {VertexAI} = require("@google-cloud/vertexai");

const project = process.env.GCLOUD_PROJECT;
const location = "us-central1";

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

/**
 * Recursively converts all keys within an object or array of objects from snake_case to camelCase.
 * * This function traverses the input structure:
 * 1. If the input is a primitive type (string, number, boolean) or null, it returns the input unchanged.
 * 2. If the input is an array, it applies the conversion to every element.
 * 3. If the input is an object, it converts keys (e.g., 'medicine_name' -> 'medicineName') and recursively
 * calls itself on the corresponding values.
 *
 * @param {object | Array<object> | string | number | boolean | null} o The input object, array, or primitive value.
 * @return {object | Array<object> | string | number | boolean | null} The object or array with keys converted to camelCase.
 */
function keysToCamel(o) {
  if (o === null || typeof o !== "object") {
    return o;
  }

  if (Array.isArray(o)) {
    return o.map(keysToCamel);
  }

  return Object.keys(o).reduce((newO, k) => {
    const newKey = k.replace(/(_\w)/g, (m) => m[1].toUpperCase());
    newO[newKey] = keysToCamel(o[k]);
    return newO;
  }, {});
}

exports.generateContentWithGemini = onCall(
    {enforceAppCheck: true, secrets: ["VERTEX_API_KEY"]},
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
        const vertexAI = new VertexAI({
          project: project,
          location: location,
        });

        const generativeModel = vertexAI.getGenerativeModel(
            {
              model: "gemini-2.5-flash-lite",
              generationConfig: generationConfig,
            },
        );

        const imagePart = {
          inlineData: {
            data: image,
            mimeType: "image/jpeg",
          },
        };

        const result = await generativeModel.generateContent(
            {
              contents: [
                {
                  role: "user", parts: [{text: prompt}, imagePart],
                },
              ],
            },
        );

        const response = result.response;
        const text = response.candidates[0].content.parts[0].text;

        // Convert from snake case to camel case:
        const snakeCaseObject = JSON.parse(text);
        const camelCaseObject = keysToCamel(snakeCaseObject);
        const finalJSONString = JSON.stringify(camelCaseObject);

        return {result: finalJSONString};
      } catch (error) {
        console.error("Vertex AI call failed.", userId, error);
        throw new HttpsError(
            "internal",
            "Generation failed.",
            error.message,
        );
      }
    },
);
