﻿namespace RemObjects.Elements.System;

type
  [Packed]
  DelphiWideString = public record
  assembly
    fStringData: ^Char;

  public

    property Length: Integer read DelphiStringHelpers.DelphiStringLength(fStringData);
    property ReferenceCount: Integer read DelphiStringHelpers.DelphiStringReferenceCount(fStringData);

    property Chars[aIndex: Integer]: Char
      read begin
        CheckIndex(aIndex);
        result := (fStringData+aIndex)^;
      end
      write begin
        CheckIndex(aIndex);
        //DelphiStringHelpers.CopyOnWriteDelphiWideString(var self);
        (fStringData+aIndex)^ := value;
      end; default;

    //
    // Operators
    //

    operator Explicit(aString: DelphiWideString): IslandString;
    begin
      result := IslandString:FromPChar(aString.fStringData);
    end;

    operator Explicit(aString: IslandString): DelphiWideString;
    begin
      result := aString:ToDelphiWideString;
    end;

    {$IF DARWIN}
    operator Explicit(aString: DelphiWideString): CocoaString;
    begin
      result := new CocoaString withBytes(aString.fStringData) length(DelphiStringHelpers.DelphiStringLength(aString.fStringData)) encoding(Foundation.NSStringEncoding.UTF16LittleEndianStringEncoding);
    end;

    operator Explicit(aString: CocoaString): DelphiWideString;
    begin
      result := aString:ToDelphiWideString;
    end;
    {$ENDIF}

    //

    operator &Add(aLeft: DelphiWideString; aRight: DelphiWideString): DelphiWideString;
    begin
      //result := :Delphi.System.Concat(aLeft, aRight);
    end;

    operator &Add(aLeft: DelphiObject; aRight: DelphiWideString): DelphiWideString;
    begin
      result := aLeft.ToString as DelphiWideString + aRight;
    end;

    operator &Add(aLeft: IslandObject; aRight: DelphiWideString): DelphiWideString;
    begin
      result := (aLeft.ToString as DelphiWideString) + aRight;
    end;

    operator &Add(aLeft: DelphiWideString; aRight: DelphiObject): DelphiWideString;
    begin
      result := aLeft + aRight.ToString;
    end;

    operator &Add(aLeft: DelphiWideString; aRight: IslandObject): DelphiWideString;
    begin
      result := aLeft + (aRight.ToString as DelphiString);
    end;

    [ToString]
    method ToString: IslandString;
    begin
      result := self as IslandString;
    end;

  assembly

    constructor; empty;

    constructor(aStringData: ^Void);
    begin
      fStringData := aStringData;
    end;

  private

    method CheckIndex(aIndex: Integer);
    begin
      if (aIndex < 1) or (aIndex > Length) then
        raise new IndexOutOfRangeException($"Index {aIndex} is out of valid bounds (1..{Length}).");
    end;

  end;
end.