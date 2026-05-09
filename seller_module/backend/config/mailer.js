const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

async function sendOtpEmail(to, otp) {
  await transporter.sendMail({
    from: `"CampusKart" <${process.env.EMAIL_USER}>`,
    to,
    subject: 'CampusKart - Verify Your Email',
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #f8f9fa; border-radius: 16px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #2D3142; margin: 0;">Welcome to CampusKart!</h2>
          <p style="color: #666; margin-top: 8px;">Your campus marketplace</p>
        </div>
        <div style="background: white; border-radius: 12px; padding: 32px; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.05);">
          <p style="color: #555; margin: 0 0 16px;">Your verification code is:</p>
          <h1 style="color: #CE6A81; letter-spacing: 10px; font-size: 36px; margin: 0; padding: 16px 0; background: #fef0f3; border-radius: 8px;">${otp}</h1>
          <p style="color: #999; font-size: 13px; margin-top: 16px;">This code expires in <b>10 minutes</b>.</p>
        </div>
        <p style="color: #aaa; font-size: 12px; text-align: center; margin-top: 20px;">If you didn't request this, please ignore this email.</p>
      </div>
    `,
  });
}

module.exports = { sendOtpEmail };
