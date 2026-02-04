// 导入 Firebase 核心和消息库
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

// 使用你在 firebase_options.dart 里的 web 配置信息
firebase.initializeApp({
    apiKey: 'AIzaSyB3f2FsRBxYp4dl92BPKoOBegvaqnWVBfs',
    appId: '1:1065683669109:web:5b56910ea9f9953f7a283c',
    messagingSenderId: '1065683669109',
    projectId: 'adroit-outlet-444914-m0',
    authDomain: 'adroit-outlet-444914-m0.firebaseapp.com',
    storageBucket: 'adroit-outlet-444914-m0.firebasestorage.app',
    measurementId: 'G-Y4FD1G7Q1H',
});

const messaging = firebase.messaging();

// 处理后台消息（即使网页关闭也能收到）
messaging.onBackgroundMessage((payload) => {
    console.log('收到后台消息: ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});