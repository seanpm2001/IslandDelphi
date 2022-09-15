﻿namespace RemObjects.Elements.System;

type
  [Packed]
  DelphiWideString = public record(sequence of Char)
  assembly
    fStringData: ^Char;

  public

    property Count: Integer read DelphiStringHelpers.DelphiStringLength(fStringData);
    property Length: Integer read DelphiStringHelpers.DelphiStringLength(fStringData);
    property ReferenceCount: Integer read DelphiStringHelpers.DelphiStringReferenceCount(fStringData);

    property Chars[aIndex: Integer]: Char
      read begin
        CheckIndex(aIndex);
        result := (fStringData+aIndex)^;
      end
      write begin
        CheckIndex(aIndex);
        if (fStringData+aIndex-1)^ ≠ value then
          (fStringData+aIndex-1)^ := value;
      end; default;

    property Chars[aIndex: &Index]: Char read Chars[aIndex.GetOffset(Length)] write Chars[aIndex.GetOffset(Length)];

    [&Sequence]
    method GetSequence: sequence of Char; iterator;
    begin
      for i := 0 to DelphiStringHelpers.DelphiStringLength(fStringData)-1 do
        yield (fStringData+i)^;
    end;

    //
    // Operators
    //

    operator Implicit(aString: InstanceType): IslandString;
    begin
      result := IslandString:FromPChar(aString.fStringData, aString.Length);
    end;

    operator Implicit(aString: InstanceType): IslandObject;
    begin
      result := IslandString:FromPChar(aString.fStringData, aString.Length);
    end;

    operator Explicit(aString: IslandString): InstanceType;
    begin
      result := DelphiStringHelpers.DelphiWideStringWithChars(aString.FirstChar, aString.Length);
    end;

    // PChar

    operator Implicit(aString: ^Char): InstanceType; {$HINT seems risky for non-nil?}
    begin
      if assigned(aString) then
        result := DelphiStringHelpers.DelphiWideStringWithChars(aString, PCharLen(aString));
    end;

    // NSString

    {$IF DARWIN}
    operator Explicit(aString: InstanceType): CocoaString;
    begin
      result := new CocoaString withBytes(aString.fStringData) length(DelphiStringHelpers.DelphiStringLength(aString.fStringData)) encoding(Foundation.NSStringEncoding.UTF16LittleEndianStringEncoding);
    end;

    operator Explicit(aString: CocoaString): InstanceType;
    begin
      var lLength := aString.length;
      var lBytes := new Char[lLength];
      aString.getCharacters(lBytes);
      result := DelphiStringHelpers.DelphiWideStringWithChars(@(lBytes[0]), lLength);
    end;
    {$ENDIF}

    // Concat

    operator &Add(aLeft: InstanceType; aRight: InstanceType): InstanceType;
    begin
      result := DelphiStringHelpers.EmptyDelphiWideStringWithCapacity(aLeft.Length+aRight.Length);
      memcpy(result.fStringData,              aLeft.fStringData,  aLeft.Length*sizeOf(Char));
      memcpy(result.fStringData+aLeft.Length, aRight.fStringData, aRight.Length*sizeOf(Char));
    end;

    // DelphiObject

    operator &Add(aLeft: DelphiObject; aRight: InstanceType): InstanceType;
    begin
      var lLeft := aLeft.ToString;
      result := DelphiStringHelpers.EmptyDelphiWideStringWithCapacity(lLeft.Length+aRight.Length);
      memcpy(result.fStringData,              lLeft.fStringData,  lLeft.Length*sizeOf(Char));
      memcpy(result.fStringData+lLeft.Length, aRight.fStringData, aRight.Length*sizeOf(Char));
    end;

    operator &Add(aLeft: InstanceType; aRight: DelphiObject): InstanceType;
    begin
      var lRight := aRight.ToString;
      result := DelphiStringHelpers.EmptyDelphiWideStringWithCapacity(aLeft.Length+lRight.Length);
      memcpy(result.fStringData,              aLeft.fStringData,  aLeft.Length*sizeOf(Char));
      memcpy(result.fStringData+aLeft.Length, lRight.fStringData, lRight.Length*sizeOf(Char));
    end;

    // IslandObject

    operator &Add(aLeft: IslandObject; aRight: InstanceType): InstanceType;
    begin
      var lLeft := aLeft.ToString;
      result := DelphiStringHelpers.EmptyDelphiWideStringWithCapacity(lLeft.Length+aRight.Length);
      memcpy(result.fStringData,              lLeft.FirstChar,    lLeft.Length*sizeOf(Char));
      memcpy(result.fStringData+lLeft.Length, aRight.fStringData, aRight.Length*sizeOf(Char));
    end;

    operator &Add(aLeft: InstanceType; aRight: IslandObject): InstanceType;
    begin
      var lRight := aRight.ToString;
      result := DelphiStringHelpers.EmptyDelphiWideStringWithCapacity(aLeft.Length+lRight.Length);
      memcpy(result.fStringData,              aLeft.fStringData, aLeft.Length*sizeOf(Char));
      memcpy(result.fStringData+aLeft.Length, lRight.FirstChar,  lRight.Length*sizeOf(Char));
    end;

    // CocoaObject

    {$IF DARWIN}
    operator &Add(aLeft: CocoaObject; aRight: InstanceType): InstanceType;
    begin
      var lLeft := aLeft.description;
      var lLength := lLeft.length;
      var lBytes := new Char[lLength];
      lLeft.getCharacters(lBytes);
      result := DelphiStringHelpers.EmptyDelphiWideStringWithCapacity(lLength+aRight.Length);
      memcpy(result.fStringData,         @(lBytes[0]),       lLength*sizeOf(Char));
      memcpy(result.fStringData+lLength, aRight.fStringData, aRight.Length*sizeOf(Char));
    end;

    operator &Add(aLeft: InstanceType; aRight: CocoaObject): InstanceType;
    begin
      var lRight := aRight.description;
      var lLength := lRight.length;
      var lBytes := new Char[lLength];
      lRight.getCharacters(lBytes);
      result := DelphiStringHelpers.EmptyDelphiWideStringWithCapacity(aLeft.Length+lLength);
      memcpy(result.fStringData,              aLeft.fStringData, aLeft.Length*sizeOf(Char));
      memcpy(result.fStringData+aLeft.Length, @(lBytes[0]),      lLength*sizeOf(Char));
    end;
    {$ENDIF}

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

  public

    // live-time management

    constructor &Copy(var aSource: DelphiWideString);
    begin
      writeLn("DelphiWideString: Copy ctor");
      if not assigned(aSource.fStringData) then
        exit;
      fStringData := DelphiStringHelpers.CopyDelphiWideString(aSource.fStringData);
    end;

    class operator Assign(var aDestination: DelphiWideString; var aSource: DelphiWideString);
    begin
      writeLn($"DelphiWideString: Assign operator {IntPtr(aSource.fStringData)} => {IntPtr(aDestination.fStringData)}");
      if (@aDestination) = (@aSource) then
        exit;
      if aDestination.fStringData = aSource.fStringData then
        exit; // is this correct, for WideString, or dio we have to copy?
      if assigned(aDestination.fStringData) then
        DelphiStringHelpers.FreeDelphiWideString(var aDestination.fStringData);
      aDestination.fStringData := DelphiStringHelpers.CopyDelphiWideString(aSource.fStringData);
    end;

    finalizer;
    begin
      writeLn($"DelphiWideString: Finalizer {IntPtr(self.fStringData)} '{self}'");
      DelphiStringHelpers.FreeDelphiWideString(var self.fStringData);
    end;

  end;

end.