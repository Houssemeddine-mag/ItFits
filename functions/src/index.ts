import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

admin.initializeApp();

const REGION = "us-central1";

const runtime = functions.runWith({
  secrets: ["OPENROUTER_API_KEY", "HF_TOKEN"],
  timeoutSeconds: 120,
  memory: "512MB",
});

const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";
const OPENROUTER_MODEL = "openrouter/free";
const HF_EDIT_URL =
  "https://router.huggingface.co/fal-ai/fal-ai/flux-2/klein/9b/edit";

const DAILY_DESIGN_LIMIT = 5;
const DAILY_CHAT_LIMIT = 100;

const MAX_MESSAGES = 40;
const MAX_TEXT_CHARS = 8000;
const MAX_PROMPT_CHARS = 4000;
const MAX_IMAGE_DATA_URL_CHARS = 8 * 1024 * 1024;

async function consumeQuota(uid: string, kind: string, limit: number) {
  const day = new Date().toISOString().slice(0, 10);
  const ref = admin.firestore().collection("rateLimits").doc(uid);
  const allowed = await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() ?? {};
    const entry = data[kind] as { day?: string; count?: number } | undefined;
    const count = entry?.day === day ? entry.count ?? 0 : 0;
    if (count >= limit) return false;
    tx.set(ref, { [kind]: { day, count: count + 1 } }, { merge: true });
    return true;
  });
  if (!allowed) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      `Daily limit reached (${limit} per day). Try again tomorrow.`
    );
  }
}

function requireAuth(context: functions.https.CallableContext): string {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }
  return context.auth.uid;
}

function invalid(message: string): never {
  throw new functions.https.HttpsError("invalid-argument", message);
}

function isImageDataUrl(v: unknown): v is string {
  return (
    typeof v === "string" &&
    /^data:image\/(jpeg|png|webp);base64,/.test(v) &&
    v.length <= MAX_IMAGE_DATA_URL_CHARS
  );
}

function sanitizeMessage(m: unknown): object {
  if (typeof m !== "object" || m === null) invalid("Bad message");
  const { role, content } = m as { role?: unknown; content?: unknown };
  if (role !== "system" && role !== "user" && role !== "assistant") {
    invalid("Bad message role");
  }
  if (typeof content === "string") {
    if (content.length > MAX_TEXT_CHARS) invalid("Message too long");
    return { role, content };
  }
  if (!Array.isArray(content) || content.length === 0 || content.length > 4) {
    invalid("Bad message content");
  }
  const parts = content.map((p: unknown) => {
    const part = p as {
      type?: unknown;
      text?: unknown;
      image_url?: { url?: unknown };
    };
    if (part?.type === "text" && typeof part.text === "string" &&
        part.text.length <= MAX_TEXT_CHARS) {
      return { type: "text", text: part.text };
    }
    const url = part?.image_url?.url;
    if (part?.type === "image_url" && isImageDataUrl(url)) {
      return { type: "image_url", image_url: { url } };
    }
    return invalid("Bad message part");
  });
  return { role, content: parts };
}

export const aiChat = runtime
  .region(REGION)
  .https.onCall(async (data: { messages?: unknown }, context) => {
    const uid = requireAuth(context);
    const messages = data?.messages;
    if (!Array.isArray(messages) || messages.length === 0 ||
        messages.length > MAX_MESSAGES) {
      invalid("messages must be a non-empty array");
    }
    const clean = messages.map(sanitizeMessage);

    await consumeQuota(uid, "chat", DAILY_CHAT_LIMIT);

    try {
      const res = await fetch(OPENROUTER_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.OPENROUTER_API_KEY ?? ""}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: OPENROUTER_MODEL,
          messages: clean,
          max_tokens: 1024,
        }),
      });
      if (!res.ok) {
        console.error("OpenRouter error", res.status, await res.text());
        throw new Error(`upstream ${res.status}`);
      }
      const body = (await res.json()) as {
        choices?: Array<{ message?: { content?: string } }>;
      };
      return { content: body.choices?.[0]?.message?.content ?? "" };
    } catch (error) {
      console.error("aiChat error:", error);
      throw new functions.https.HttpsError("internal", "AI chat failed");
    }
  });

interface DesignRequest {
  imageUrls?: unknown;
  prompt?: unknown;
  style?: unknown;
  roomType?: unknown;
}

export const generateDesign = runtime
  .region(REGION)
  .https.onCall(async (data: DesignRequest, context) => {
    const uid = requireAuth(context);

    const imageUrls = data?.imageUrls;
    const prompt = data?.prompt;
    const style = typeof data?.style === "string" ? data.style.slice(0, 100) : "";
    if (!Array.isArray(imageUrls) || imageUrls.length === 0) {
      invalid("imageUrls is required");
    }
    const image: unknown = imageUrls[0];
    if (!isImageDataUrl(image)) {
      invalid("imageUrls[0] must be an image data URL");
    }
    if (typeof prompt !== "string" || prompt.length === 0 ||
        prompt.length > MAX_PROMPT_CHARS) {
      invalid("prompt is required");
    }

    await consumeQuota(uid, "design", DAILY_DESIGN_LIMIT);

    try {
      const fullPrompt = [
        prompt,
        "High quality, photorealistic, 4K resolution, professional interior photography, perfect lighting, magazine quality.",
      ].join(" ");

      const apiResponse = await fetch(HF_EDIT_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.HF_TOKEN ?? ""}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ prompt: fullPrompt, image_urls: [image] }),
      });

      if (!apiResponse.ok) {
        console.error("HF API error:", apiResponse.status, await apiResponse.text());
        throw new Error(`upstream ${apiResponse.status}`);
      }

      const result = (await apiResponse.json()) as {
        images?: Array<{ url?: string }>;
      };
      const generatedImageUrl = result.images?.[0]?.url;
      if (!generatedImageUrl || !/^https:\/\//.test(generatedImageUrl)) {
        throw new Error("No image returned from AI");
      }

      const imageResponse = await fetch(generatedImageUrl);
      if (!imageResponse.ok) {
        throw new Error("Failed to download generated image");
      }
      const contentType =
        imageResponse.headers.get("content-type") ?? "image/png";
      const imageBuffer = await imageResponse.buffer();

      return {
        designs: [
          {
            imageUrl: `data:${contentType};base64,${imageBuffer.toString("base64")}`,
            style,
            prompt: fullPrompt,
          },
        ],
      };
    } catch (error) {
      console.error("generateDesign error:", error);
      throw new functions.https.HttpsError("internal", "Design generation failed");
    }
  });
