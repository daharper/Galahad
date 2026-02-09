{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Xml
  Author:      David Harper
  License:     MIT
  History:     2026-08-02  Initial version
  Purpose:     Basic XML Object and Parser for simple persistance requirements.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Xml;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  Base.Core;

type
  { Currently, just basic XML entities are mapped, but given the leisure, see this page:

    https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references

    and map all entities accepted by the HTML5 specification.

    Note, Unicode characters can be expressed as such:

    &apos;        =>     #$0027
    &DownBreve;   =>     #$0020 + #$0311 + #$0311
    &TripleDot;   =>     #$0020 + #$20DB + #$20DB + #$20DB

    Ordinary mappings as per normal:

    &Tab;         =>     #9
    &NewLine;     =>     #10
    &dollar;      =>     '$'
    &lpar;        =>     '('
  }
  TBvXmlEntity = (
    xAmpersand,
    xLessThan,
    xGreaterThan,
    xApostrophe,
    xQuote
  );

implementation

end.
