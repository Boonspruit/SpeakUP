import test from "node:test";
import assert from "node:assert/strict";
import { validTalkingPoints, fallbackTalkingPoints } from "./talking-points.js";

test("talking points require three distinct bounded strings", () => {
  assert.equal(validTalkingPoints(["A", "B"]), null);
  assert.equal(validTalkingPoints(["A", " a ", "B"]), null);
  assert.equal(validTalkingPoints(["A", {}, "B"]), null);
  assert.equal(validTalkingPoints(["A", " ", "B"]), null);
  assert.equal(validTalkingPoints(["A", "B", "word ".repeat(36)]), null);
  assert.deepEqual(validTalkingPoints([" One? ", "Two?", "Three?"]), ["One?", "Two?", "Three?"]);
});
test("legacy fallback supplies prompts instead of script paragraphs", () => {
  const points = fallbackTalkingPoints("Weekly Team Update");
  assert.deepEqual(validTalkingPoints(points), points);
  assert.ok(points.every(point => point.endsWith("?")));
  assert.ok(validTalkingPoints(fallbackTalkingPoints("word ".repeat(100))));
});
