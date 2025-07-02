/* eslint-disable linebreak-style */
/**
 * A helper function to determine a date range from text.
 * @param {string} text The user's message.
 * @return {{startDate: Date, endDate: Date, timeFrameText: string}} A date range.
 */
export function getDateRangeFromText(text: string): {startDate: Date, endDate: Date, timeFrameText: string} {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const lowerCaseText = text.toLowerCase();

  let startDate = new Date(0); // Default to all time
  let endDate = new Date();
  let timeFrameText = "of all time";

  if (lowerCaseText.includes("this month")) {
    startDate = new Date(today.getFullYear(), today.getMonth(), 1);
    timeFrameText = "for this month";
  } else if (lowerCaseText.includes("last month")) {
    startDate = new Date(today.getFullYear(), today.getMonth() - 1, 1);
    endDate = new Date(today.getFullYear(), today.getMonth(), 0);
    timeFrameText = "for last month";
  } else if (lowerCaseText.includes("last week")) {
    startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - today.getDay() - 6);
    endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - today.getDay());
    timeFrameText = "for last week";
  } else if (lowerCaseText.includes("this week")) {
    startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - today.getDay() + 1);
    timeFrameText = "for this week";
  } else if (lowerCaseText.includes("yesterday")) {
    startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    endDate = today;
    timeFrameText = "for yesterday";
  } else if (lowerCaseText.includes("today")) {
    startDate = today;
    timeFrameText = "for today";
  }

  return {startDate, endDate, timeFrameText};
}
