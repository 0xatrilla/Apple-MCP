import { runJxa } from "./process.js";

export async function searchMail(query: string, limit = 10) {
  const script = `
function run(argv) {
  const query = (argv[0] || "").toLowerCase();
  const limit = Number(argv[1] || "10");
  const Mail = Application("Mail");
  const out = [];
  for (const account of Mail.accounts()) {
    for (const mailbox of account.mailboxes()) {
      for (const message of mailbox.messages()) {
        const subject = message.subject() || "";
        const sender = message.sender() || "";
        if (!query || subject.toLowerCase().includes(query) || sender.toLowerCase().includes(query)) {
          out.push({ id: message.id(), subject, sender, mailbox: mailbox.name(), dateReceived: String(message.dateReceived()) });
        }
        if (out.length >= limit) return JSON.stringify(out);
      }
    }
  }
  return JSON.stringify(out);
}`;
  return JSON.parse(await runJxa(script, [query, String(limit)]));
}

export async function readMail(id: string) {
  const script = `
function run(argv) {
  const target = Number(argv[0]);
  const Mail = Application("Mail");
  for (const account of Mail.accounts()) {
    for (const mailbox of account.mailboxes()) {
      for (const message of mailbox.messages()) {
        if (message.id() === target) {
          return JSON.stringify({ id: message.id(), subject: message.subject(), sender: message.sender(), mailbox: mailbox.name(), content: message.content() });
        }
      }
    }
  }
  throw new Error("Message not found");
}`;
  return JSON.parse(await runJxa(script, [id]));
}

export async function createDraft(to: string[], subject: string, body: string) {
  const script = `
function run(argv) {
  const to = JSON.parse(argv[0]);
  const subject = argv[1];
  const body = argv[2];
  const Mail = Application("Mail");
  const message = Mail.OutgoingMessage({ subject, content: body, visible: true });
  Mail.outgoingMessages.push(message);
  for (const address of to) {
    message.toRecipients.push(Mail.Recipient({ address }));
  }
  return JSON.stringify({ id: message.id(), subject, recipients: to, visible: true });
}`;
  return JSON.parse(await runJxa(script, [JSON.stringify(to), subject, body]));
}

export async function sendDraft(id: string) {
  const script = `
function run(argv) {
  const target = Number(argv[0]);
  const Mail = Application("Mail");
  for (const message of Mail.outgoingMessages()) {
    if (message.id() === target) {
      message.send();
      return JSON.stringify({ id: target, sent: true });
    }
  }
  throw new Error("Draft not found");
}`;
  return JSON.parse(await runJxa(script, [id]));
}
