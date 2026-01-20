# Feature Verification Guide

Use this guide to locate and test each of the 7 new features quickly in the app.

## 1. Physical vs. E-Code Rates
**Where to test:**
- **App (User):** Go to **Sell Gift Cards** -> Select a Card (e.g., Amazon).
  - *Look for:* A toggle switch for "Physical Card" vs "E-Code".
  - *Action:* Toggle it. The rate per dollar ($) displayed below should change.
- **Admin Panel:** Go to **Dashboard** -> **Manage Gift Cards** (Card Icon) -> Click **Edit** (Pencil) on a card.
  - *Look for:* Separate input fields for "Physical Rate" and "E-Code Rate".

## 2. Admin Control (Min/Max/Denominations)
**Where to test:**
- **Admin Panel:** Go to **Dashboard** -> **Manage Gift Cards** -> **Edit** a card.
  - *Look for:* "Min Value", "Max Value", and "Allowed Denominations" inputs.
  - *Action:* Set "Min" to 50. Save.
- **App (User):** Go to **Sell Gift Cards** -> Select that card.
  - *Action:* Try typing "20" in the amount.
  - *Expected:* It should show an error or hint that the minimum is 50.

## 3. Trade Status Image Uploads
**Where to test:**
- **Admin Panel:** Go to **Dashboard** -> **Transaction List** -> Tap any **Pending** transaction.
  - *Look for:* Scroll down to find the **"Admin Proof"** section.
  - *Action:* Tap the **Upload Image** button. Select a screenshot.
  - *Expected:* The image appears in the gallery section.

## 4. Order Assignment Locking
**Where to test:**
- **Admin Panel:** Go to **Dashboard** -> **Transaction List** -> Tap a **Pending** transaction.
  - *Look for:* A **"Claim Order"** button at the top right (or near status).
  - *Action:* Tap it.
  - *Expected:* Status changes to "Locked by you". If you login as a *different* admin, this button should be disabled or show "Locked by [Name]".

## 5. Admin Performance Tracking
**Where to test:**
- **Admin Panel:** Go to **Dashboard**.
  - *Look for:* A new **Analytics Icon** 📊 in the top app bar (next to Wallet/Notification icons).
  - *Action:* Tap it.
  - *Expected:* Opens the **Performance Dashboard** showing "Total Completed", "Pending", and a Leaderboard.

## 6. Admin Chat Visibility
**Where to test:**
- **Admin Panel:** Go to **Dashboard** -> **Transaction List** -> Tap a transaction.
  - *Look for:* A **Chat Icon** 💬 in the top right app bar actions.
  - *Action:* Tap it.
  - *Expected:* Opens the **Transaction Chat** screen where you can message the user.

## 7. Dispute/Support Bot
**Where to test:**
- **Currently:** We created the screen `SupportChatScreen` but haven't added a button to it yet.
- **Temporary Access:** I can replace a button on the dashboard temporarily, or we can add it to the **Settings** screen now for you to test.

> **Note:** Ensure you have run all 5 SQL scripts in Supabase before testing!
