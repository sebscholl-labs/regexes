# frozen_string_literal: true

module Regexes
  # ── Mail ──────────────────────────────────────────────────────────────────────────────────────────────────

  any_label = '[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
  atext     = "[A-Za-z0-9!\#$%&'*+/=?^_`{|}~-]"
  dot_atom  = "#{atext}+(?:\\.#{atext}+)*"

  EMAIL_ADDRESS       = Expression.new(
    "(?<local>[A-Za-z0-9.!\#$%&'*+/=?^_`{|}~-]+)@(?<domain>#{any_label}(?:\\.#{any_label})*)"
  )
  MESSAGE_ID          = Expression.new("<(?<id_left>#{dot_atom})@(?<id_right>#{dot_atom}|\\[[!-Z^-~]*\\])>")
  HEADER_FIELD_NAME   = Expression.new('[!-9;-~]+')
  FOLDED_LINE_BREAK   = Expression.new('\r\n(?=[ \t])')
  UNFOLDED_LINE_BREAK = Expression.new('\r\n(?![ \t])')

  # The address an HTML form's +type=email+ input accepts (WHATWG HTML §4.10.5.1.5), so a browser and a server
  # reach the same verdict: +ada@acme.example+, +a+b@x+. Like the browser, it allows a domain of one label
  # and dots anywhere in the local part. Whether the address exists is for the mail to find out. Its parts are
  # captured as +local+ and +domain+.
  #
  # @return [Expression] an email address, as +ada@acme.example+
  def email_address = EMAIL_ADDRESS

  # +Regexes.message_id.whole+ matches +<01890a5d@acme.example>+ and +<a.b@[127.0.0.1]>+, never one without its
  # angle brackets or its +@+. It captures +id_left+ and +id_right+ (RFC 5322 §3.6.4).
  #
  # @return [Expression] a mail message's identifier, as its Message-ID, In-Reply-To and References headers hold
  #   it
  def message_id = MESSAGE_ID

  # +Regexes.header_field_name.whole+ matches +Subject+, +X-Original-To+ and +DKIM-Signature+, never +Sub ject+
  # or +Subject:+ (RFC 5322 §2.2: printable ASCII but the colon).
  #
  # @return [Expression] the name of a mail header field
  def header_field_name = HEADER_FIELD_NAME

  # A header that runs over several lines is folded: its line breaks are each followed by a space or tab, and
  # unfolding it removes them (RFC 5322 §2.2.3).
  #
  # @return [Expression] a CRLF followed by a space or tab, which it does not take
  def folded_line_break = FOLDED_LINE_BREAK

  # @return [Expression] a CRLF not followed by a space or tab: one that ends a header, never one inside it
  def unfolded_line_break = UNFOLDED_LINE_BREAK
end
