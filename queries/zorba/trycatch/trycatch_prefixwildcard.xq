declare namespace err="http://www.w3.org/2005/xqt-errors";
try {
  fn:error(fn:QName("urn", "foo"), "blub")
} catch *:foo {
  "boom shaka"
}
