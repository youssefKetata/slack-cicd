import nodemailer from 'nodemailer'

export default async function sendEmail(
  to: string,
  subject: string,
  html?: string,
  text?: string
): Promise<boolean> {
  try {
    // Create a transporter with Gmail configuration
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.SMTP_USERNAME,
        pass: process.env.SMTP_PASSWORD, // Use an app password if 2FA is enabled
      },
    })

    // Verify connection configuration
    await transporter.verify().catch(console.error)

    // Send the email
    const info = await transporter.sendMail({
      from: process.env.SMTP_USERNAME,
      to,
      subject,
      html,
      text,
    })

    console.log('Email sent: %s', info.messageId)
    return true
  } catch (error) {
    console.error('Failed to send email:', error)
    return false
  }
}
