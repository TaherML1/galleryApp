/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
/* eslint-disable require-jsdoc */
/* eslint-disable max-len */
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const axios = require("axios");
const {google} = require("googleapis");

admin.initializeApp();

// Function to get an access token using a service account
async function getAccessToken() {
  const clientEmail = functions.config().serviceaccount.clientemail;
  const privateKey = functions.config().serviceaccount.privatekey.replace(/\\n/g, "\n");
  const projectId = functions.config().project.id;

  const client = new google.auth.JWT(
      clientEmail,
      null,
      privateKey,
      ["https://www.googleapis.com/auth/firebase.messaging"],
  );
  const tokens = await client.authorize();
  return tokens.access_token;
}

exports.checkMemoriesAndSendNotification = functions.pubsub.schedule("every 5 minutes").onRun(
    async (context) => {
      const today = new Date();
      const todayDate = today.toISOString().split("T")[0]; // Get today's date (YYYY-MM-DD)
      console.log(`Function triggered at: ${new Date().toISOString()} | Today's date: ${todayDate}`);

      try {
        // Get all user documents from Firestore
        const usersSnapshot = await admin.firestore().collection("users").get();
        console.log(`Retrieved ${usersSnapshot.size} users from Firestore.`);

        // Get FCM tokens from all users
        const fcmTokens = [];
        usersSnapshot.forEach((userDoc) => {
          const fcmToken = userDoc.data()?.fcmToken;
          if (fcmToken) {
            fcmTokens.push(fcmToken);
          }
        });
        console.log(`Collected ${fcmTokens.length} FCM tokens.`);

        if (fcmTokens.length === 0) {
          console.log("No FCM tokens found, skipping notifications.");
          return;
        }

        // Fetch all photos from the Firestore collection
        const yearsSnapshot = await admin.firestore().collectionGroup("photos").get();

        console.log(`Retrieved ${yearsSnapshot.size} photos.`);

        // Loop through each photo
        yearsSnapshot.forEach(async (doc) => {
          const photoData = doc.data();
          const timestamp = photoData.timestamp;

          if (timestamp && typeof timestamp === "string") {
            const photoDate = timestamp.split("T")[0]; // Extract the date part (YYYY-MM-DD)

            // Compare the date part (YYYY-MM-DD) with today's date
            if (photoDate === todayDate) {
              console.log(`Photo uploaded today: ${timestamp}. Skipping...`);
              return;
            }

            const photoMonthDay = timestamp.slice(5, 10); // Extract the month and day part (MM-DD)
            const todayMonthDay = todayDate.slice(5, 10); // Extract the month and day part (MM-DD)

            // Compare the month and day with today's date
            if (photoMonthDay === todayMonthDay) {
              console.log(`Matching memory found for today: ${timestamp}. Preparing notification...`);

              // Prepare the FCM notification payload
              const payload = {
                notification: {
                  title: "Memory Reminder",
                  body: `Check out this memory from ${timestamp.split("T")[0]}!`,
                  imageUrl: photoData.url,
                  sound: "default",
                },
                data: {
                  photoUrl: photoData.url,
                  description: photoData.description,
                  timestamp: photoData.timestamp,
                },
              };

              // Loop through each FCM token and send a notification
              for (const token of fcmTokens) {
                // Prepare the message object for v1 API
                const message = {
                  message: {
                    token: token,
                    notification: {
                      title: payload.notification.title,
                      body: payload.notification.body,
                      image: payload.notification.imageUrl,
                    },
                    data: payload.data,
                  },
                };

                // Log the request payload for debugging
                console.log(`Request Payload: ${JSON.stringify(message)}`);

                // Send the notification using the v1 API
                try {
                  // Get an access token
                  const accessToken = await getAccessToken();

                  // Log the access token for debugging
                  console.log(`Access Token: ${accessToken}`);

                  // Send the message using axios to the v1 API
                  const response = await axios.post(
                      `https://fcm.googleapis.com/v1/projects/${functions.config().project.id}/messages:send`,
                      message,
                      {
                        headers: {
                          "Authorization": `Bearer ${accessToken}`,
                          "Content-Type": "application/json",
                        },
                      },
                  );

                  console.log(`Notification sent for memory to ${response.data.successCount} devices`);
                } catch (error) {
                  console.error(`Failed to send notification: ${error.response ? JSON.stringify(error.response.data) : error.message}`);
                }
              }
            } else {
              console.log(`No matching memory found for today: ${timestamp.split("T")[0]}. Skipping...`);
            }
          } else {
            console.error(`Invalid or missing timestamp for photo ID ${doc.id}`);
          }
        });
      } catch (error) {
        console.error(`Error in function execution: ${error}`);
      }

      return null;
    },
);
