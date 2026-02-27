importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Ваша конфигурация Firebase из firebase_options.dart (для веба)
const firebaseConfig = {
  apiKey: "AIzaSyCWfyTHG9LSSSUl2clOz7nvLnkGTUilW6k",
  authDomain: "metan-chat.firebaseapp.com",
  projectId: "metan-chat",
  storageBucket: "metan-chat.firebasestorage.app",
  messagingSenderId: "1003268097101",
  appId: "1:1003268097101:web:220dcb7d7b353feeb4c804"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message: ', payload);
  
  const notificationTitle = payload.notification?.title || 'METAH GYM';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});