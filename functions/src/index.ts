import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

admin.initializeApp();

const REGION = "us-central1";
const HF_TOKEN = process.env.HF_TOKEN || "";

const DAILY_LIMIT = 5;
const rateLimitCache = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const limit = rateLimitCache.get(userId);
  if (!limit || now > limit.resetAt) {
    rateLimitCache.set(userId, { count: 1, resetAt: now + 86400000 });
    return true;
  }
  if (limit.count >= DAILY_LIMIT) return false;
  limit.count++;
  return true;
}

interface DesignRequest {
  imageUrls: string[];
  prompt: string;
  style: string;
  roomType: string;
}

export const generateDesign = functions
  .region(REGION)
  .https.onCall(async (data: DesignRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const userId = context.auth.uid;
    const { imageUrls, prompt, style } = data;

    if (!imageUrls || imageUrls.length === 0 || !prompt) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "imageUrls and prompt are required"
      );
    }

    if (!checkRateLimit(userId)) {
      throw new functions.https.HttpsError(
        "resource-exhausted",
        "Daily design limit reached (5 per day). Try again tomorrow."
      );
    }

    try {
      const apiUrl =
        "https://router.huggingface.co/fal-ai/fal-ai/flux-2/klein/9b/edit";

      const firstImageUrl = imageUrls[0];
      const formattedUrl = firstImageUrl.startsWith("data:")
        ? firstImageUrl
        : `data:image/jpeg;base64,${firstImageUrl}`;

      const fullPrompt = [
        prompt,
        "High quality, photorealistic, 4K resolution, professional interior photography, perfect lighting, magazine quality.",
      ].join(" ");

      const apiResponse = await fetch(apiUrl, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${HF_TOKEN}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          prompt: fullPrompt,
          image_urls: [formattedUrl],
        }),
      });

      if (!apiResponse.ok) {
        const errorText = await apiResponse.text();
        console.error("HF API error:", apiResponse.status, errorText);
        throw new Error(`AI generation failed: ${apiResponse.status}`);
      }

      const result = (await apiResponse.json()) as {
        images: Array<{ url: string; content_type: string }>;
        timings: { inference: number };
        seed: number;
      };

      if (!result.images || result.images.length === 0) {
        throw new Error("No images returned from AI");
      }

      const generatedImageUrl = result.images[0].url;

      const imageResponse = await fetch(generatedImageUrl);
      if (!imageResponse.ok) {
        throw new Error("Failed to download generated image");
      }
      const imageBuffer = await imageResponse.buffer();
      const generatedBase64 = `data:image/png;base64,${imageBuffer.toString("base64")}`;

      return {
        designs: [
          {
            imageUrl: generatedBase64,
            style: style,
            prompt: fullPrompt,
          },
        ],
      };
    } catch (error: any) {
      console.error("generateDesign error:", error);
      throw new functions.https.HttpsError(
        "internal",
        error.message || "Design generation failed"
      );
    }
  });
