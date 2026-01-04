const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Function to update a user's password (requires Admin SDK)
exports.updateUserPassword = functions.https.onCall(async (data, context) => {
  // 1. Security: Check if request is made by an authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Note: In a production app, you should also check if the user has 'admin' claims.
  // For this prototype, we assume any authenticated user with access to this screen is authorized.

  const uid = data.uid;
  const newPassword = data.password;

  if (!uid || !newPassword) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with 'uid' and 'password'."
    );
  }

  try {
    // 2. Update the password using Admin SDK
    await admin.auth().updateUser(uid, {
      password: newPassword,
    });
    return { success: true, message: "Password updated successfully." };
  } catch (error) {
    console.error("Error updating user password:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

// Function to generate a password reset link (for manual sharing via SMS/WhatsApp)
exports.generatePasswordResetLink = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const email = data.email;
  if (!email) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with 'email'."
    );
  }

  try {
    const link = await admin.auth().generatePasswordResetLink(email);
    return { link: link };
  } catch (error) {
    console.error("Error generating reset link:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
