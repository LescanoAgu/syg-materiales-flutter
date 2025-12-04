importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

// Configuración DEV (La misma de firebase_options_dev.dart)
firebase.initializeApp({
  apiKey: "AIzaSyAN6fIKLsemDuTkOFwXxnGdyxXkOeWHOSM",
  authDomain: "syg-15007.firebaseapp.com",
  projectId: "syg-15007",
  storageBucket: "syg-15007.firebasestorage.app",
  messagingSenderId: "1007424963854",
  appId: "1:1007424963854:web:8b991ce29a4591718f035f"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png' // Usamos tu nuevo logo
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});