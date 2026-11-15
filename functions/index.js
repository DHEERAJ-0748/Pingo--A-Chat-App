const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Trigger on new message creation and send a push notification to the receiver.
exports.sendChatNotification = functions.firestore
    .document('chats/{chatId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
  const message = snap.data();
  const { senderId, receiverId, text } = message;
  const chatId = context.params.chatId;

  // Do not send notification to self or if missing data.
  if (!receiverId || receiverId === senderId) {
    return null;
  }

  // Retrieve receiver's FCM token.
  const receiverDoc = await admin.firestore()
      .collection('users')
      .doc(receiverId)
      .get();
  const token = receiverDoc.get('fcmToken');
  if (!token) {
    console.log('No FCM token for user', receiverId);
    return null;
  }

  // Retrieve sender's display name for the notification title.
  const senderDoc = await admin.firestore()
      .collection('users')
      .doc(senderId)
      .get();
  const senderName = senderDoc.get('displayName') || 'New Message';

  const payload = {
    notification: {
      title: senderName,
      body: text,
      sound: 'default',
    },
    data: {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      chatId: chatId,
      otherUserUid: senderId,
    },
  };

  // Send the notification via FCM.
  try {
    const response = await admin.messaging().sendToDevice(token, payload);
    console.log('Notification sent response:', response);
    return response;
  } catch (error) {
    console.error('Error sending notification:', error);
    return null;
  }
});
