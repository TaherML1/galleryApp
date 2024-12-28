/* eslint-disable require-jsdoc */
/* eslint-disable no-unused-vars */
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

exports.checkMemoriesAndSendNotification = functions.pubsub.schedule("every 30 minutes").onRun(
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

        // Aggregate photos that match today's date
        const matchingPhotos = [];
        // Aggregate photos that match today's date, but exclude photos from the current year
        yearsSnapshot.forEach((doc) => {
          const photoData = doc.data();
          const timestamp = photoData.timestamp;

          if (timestamp && typeof timestamp === "string") {
            const photoDate = timestamp.split("T")[0]; // Extract the date part (YYYY-MM-DD)
            const photoMonthDay = timestamp.slice(5, 10); // Extract the month and day part (MM-DD)
            const todayMonthDay = todayDate.slice(5, 10); // Extract the month and day part (MM-DD)

            // Extract the year from the photo's timestamp
            const photoYear = parseInt(timestamp.slice(0, 4), 10); // Extract the year (YYYY)
            const currentYear = today.getFullYear(); // Get the current year (e.g., 2024)

            // Compare the month and day with today's date and check if the photo is from a previous year
            if (photoMonthDay === todayMonthDay && photoYear < currentYear) {
              matchingPhotos.push(photoData);
            }
          }
        });

        if (matchingPhotos.length === 0) {
          console.log("No matching memories found for today.");
          return;
        }

        console.log(`Found ${matchingPhotos.length} matching memories for today.`);

        // Select a photo to display in the notification
        const selectedPhoto = matchingPhotos[0]; // You can choose any logic to select the photo

        // Prepare the FCM notification payload
        const payload = {
          notification: {
            title: "Birlikteki Anılarımız",
            body: `Bugün, birlikte geçirdiğimiz o özel anlardan birini hatırlamak ister misin?`,
            image: selectedPhoto.url,
            sound: "default",
          },
          data: {},
        };


        // Add each photo to the data field with unique keys
        matchingPhotos.forEach((photo, index) => {
          payload.data[`photo_${index}_url`] = photo.url;
          payload.data[`photo_${index}_description`] = photo.description;
          payload.data[`photo_${index}_timestamp`] = photo.timestamp;
        });

        // Loop through each FCM token and send a notification
        for (const token of fcmTokens) {
          // Prepare the message object for v1 API
          const message = {
            message: {
              token: token,
              notification: {
                title: payload.notification.title,
                body: payload.notification.body,
                image: payload.notification.image, // Include the image URL here
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
      } catch (error) {
        console.error(`Error in function execution: ${error}`);
      }

      return null;
    },
);
