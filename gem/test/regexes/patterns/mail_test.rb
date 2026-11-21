# frozen_string_literal: true

require 'test_helper'

# Tests for mail's shapes: addresses, message identifiers, header names and folding.
class RegexesMailTest < RegexesTestCase
  cases({
          email_address:       [%w[ada@acme.example a+b@x ada.lovelace@acme.example ADA@ACME.EXAMPLE a@mail.acme.co.uk
                                   user!#$%&'*+/=?^_`{|}~-@x .a@x a..b@x a@1.2.3.4],
                                ['ada', '@acme.example', 'ada@', 'a da@x', 'a@b@c', 'ada@acme..example', 'ada@-acme.example',
                                 'ada@acme-.example', 'ada@acme.example.', 'ada@acme_x.example', '"ada"@acme.example',
                                 'ada@[127.0.0.1]', 'adä@acme.example', 'ada@äcme.example', "ada@#{'a' * 64}.example",
                                 'ada(x)@acme.example', '']],
          message_id:          [%w[<01890a5d@acme.example> <a.b@[127.0.0.1]> <x+y=z@mail.acme.example> <1@x>],
                                %w[01890a5d@acme.example <01890a5d.acme.example> <@acme.example> <a@> <a..b@x> <a@b@c>] +
                                  ['<a@[1[2]>', '<a b@x>', '']],
          header_field_name:   [%w[Subject X-Original-To DKIM-Signature a Received-SPF],
                                ['Sub ject', 'Subject:', '', "Subj\u00E9ct", "Sub\tject"]],
          folded_line_break:   [[], ["\r\n", "\r\n ", "\n ", ' ']],
          unfolded_line_break: [["\r\n"], ["\r\n ", "\r\n\t", "\n", "\r", '']]
        }, defined_in: 'mail')

  test 'an email address captures its local part' do
    assert_equal 'ada', Regexes.email_address.match('ada@acme.example')[:local]
  end

  test 'an email address captures its domain' do
    assert_equal 'acme.example', Regexes.email_address.match('ada@acme.example')[:domain]
  end

  test 'an email address in text is found without the words around it' do
    assert_equal 'ada@acme.example', 'write to ada@acme.example today'[Regexes.email_address]
  end

  test 'a message id captures the part before the @' do
    assert_equal '01890a5d', Regexes.message_id.match('<01890a5d@acme.example>')[:id_left]
  end

  test 'a message id captures the part after the @' do
    assert_equal 'acme.example', Regexes.message_id.match('<01890a5d@acme.example>')[:id_right]
  end

  test 'a folded line break is a CRLF before a space or tab, which it leaves' do
    assert_equal 'Subject: a b', "Subject: a\r\n b".gsub(Regexes.folded_line_break, '')
  end

  test 'a folded line break before a tab is found' do
    assert_equal ["\r\n"], "a\r\n\tb".scan(Regexes.folded_line_break)
  end

  test 'a CRLF before text is not folded' do
    assert_empty "a\r\nb".scan(Regexes.folded_line_break)
  end

  test 'an unfolded line break is a CRLF that ends a header' do
    assert_equal ["Subject: a\r\n b", 'To: c'], "Subject: a\r\n b\r\nTo: c".split(Regexes.unfolded_line_break)
  end

  test 'a header field name leads a header line' do
    assert_equal 'X-Original-To', 'X-Original-To: ada@acme.example'[Regexes.header_field_name.followed_by(Regexes.literal(':'))]
  end
end
