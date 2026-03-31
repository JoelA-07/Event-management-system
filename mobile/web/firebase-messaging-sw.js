importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBv92aYV9N3kgIPs8xcoijVqpTUfdu12qA',
  authDomain: 'jirehevent.firebaseapp.com',
  projectId: 'jirehevent',
  storageBucket: 'jirehevent.firebasestorage.app',
  messagingSenderId: '644785458469',
  appId: '1:644785458469:web:3e711bc30906ca25e19ecc',
  measurementId: 'G-FH3QYD9FCB',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notification = payload.notification || {};
  const title = notification.title || 'Notification';
  const options = {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
  };

  self.registration.showNotification(title, options);
});
