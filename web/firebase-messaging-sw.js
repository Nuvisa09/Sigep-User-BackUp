importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyAjR2dkx8DdOrbfkNu1xG6hjUkcxkWD9yg",
  authDomain: "orderjasa-7643c.firebaseapp.com",
  projectId: "orderjasa-7643c",
  storageBucket: "orderjasa-7643c.firebasestorage.app",
  messagingSenderId: "1058475941726",
  appId: "1:1058475941726:web:41e595c2ebb858fe1bf9cf",
  measurementId: "G-RBLS8HGFM5",
  databaseURL: "..."
});

const messaging = firebase.messaging();

messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            const title = payload.notification.title;
            const options = {
                body: payload.notification.score
              };
            return registration.showNotification(title, options);
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});