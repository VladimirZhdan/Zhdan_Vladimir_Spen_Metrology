program metric_of_Spen;

{$APPTYPE CONSOLE}

uses
  SysUtils, RegExpr;

type
  T_Identifier = record
		Name: String;
		Count_of_Spen: Integer;
		Access: Boolean;
	end;

  T_List_Identifier = array of T_Identifier;

  T_Subprogramm = record
    Name: String;
    List_Identifier: T_List_Identifier;
  end;

  T_List_Subprogramm = array of T_Subprogramm;

  T_Operator = record
    Value: string;
    Component_Flag: Boolean;
  end;

  T_file_of_source_code = file of Char;

function Check_Insertability_of_Symbol(Symbol: Char): Boolean;
begin
  case Symbol of
    #13, #10, #9: Result := False;
  else
    Result := True;
  end;
end;

function Check_Insertability_of_Manipulate_Symbol(Symbol: Char; Amount_of_Round_Brackets, Amount_of_Curly_Brackets: Integer;
                                                  Even_number_of_Single_Quotation_Marks, Even_number_of_Quotation_Marks: Boolean): Boolean;
begin
  case Symbol of
    '(', ')', '/', '*': Result := not(Even_number_of_Single_Quotation_Marks or Even_number_of_Quotation_Marks);
    '{', '}': Result := (Amount_of_Round_Brackets = 0) and (not(Even_number_of_Single_Quotation_Marks or Even_number_of_Quotation_Marks));
    #39: Result := not(Even_number_of_Quotation_Marks);
    #34: Result := not(Even_number_of_Single_Quotation_Marks);
    ';': Result := (Amount_of_Round_Brackets = 0) and (Amount_of_Curly_Brackets = 0) and (not(Even_number_of_Single_Quotation_Marks or Even_number_of_Quotation_Marks));
  else
    Result := False;
  end;
end;


function Define_Next_Operator(const Name_of_file_with_Code: string; var Position_in_file_with_Code: LongInt): T_Operator;
var
  Current_symbol: Char;
  Previous_symbol: Char;
  Count_of_Round_Brackets: Integer;
  Count_of_Curly_Brackets: Integer;
  Even_number_of_Single_Quotation_Marks: Boolean;
  Even_number_of_Quotation_Marks: Boolean;
  End_of_Operator_Flag: Boolean;
  Insertability_of_Symbol: Boolean;
  File_of_Code: file of Char;
begin
  Result.Value := '';
  Result.Component_Flag := False;
  Previous_symbol := ' ';
  Count_of_Round_Brackets := 0;
  Count_of_Curly_Brackets := 0;
  Even_number_of_Single_Quotation_Marks := False;
  Even_number_of_Quotation_Marks := False;
  End_of_Operator_Flag := False;

  assignFile(File_of_Code, Name_of_file_with_Code);
  reset(File_of_Code);
  seek(File_of_Code, Position_in_file_with_Code);
  repeat
    read(File_of_Code, Current_symbol);
    if Check_Insertability_of_Symbol(Current_symbol) then
    begin
      Result.Value := Result.Value + Current_symbol;
      Insertability_of_Symbol := Check_Insertability_of_Manipulate_Symbol(Current_symbol, Count_of_Round_Brackets, Count_of_Curly_Brackets,
                                                                           Even_number_of_Single_Quotation_Marks, Even_number_of_Quotation_Marks);
      case Current_symbol of
        '{':
          begin
            if Insertability_of_Symbol then
            begin
              Result.Component_Flag := True;
              Inc(Count_of_Curly_Brackets);
            end;
          end;
        '(':
          begin
            if Insertability_of_Symbol then
              Inc(Count_of_Round_Brackets);
          end;
        ')':
          begin
            if Insertability_of_Symbol then
              Dec(Count_of_Round_Brackets);
          end;
        '}':
          begin
            if Insertability_of_Symbol then
              Dec(Count_of_Curly_Brackets);
            if (Count_of_Curly_Brackets = 0)then
              End_of_Operator_Flag := True;
          end;
        ';':
          begin
            if Insertability_of_Symbol then
              End_of_Operator_Flag := True;
          end;
        #39:
          begin
            if Insertability_of_Symbol then
            begin
              Even_number_of_Single_Quotation_Marks := not(Even_number_of_Single_Quotation_Marks);
            end;
          end;
        #34:
          begin
            if Insertability_of_Symbol then
            begin
              Even_number_of_Quotation_Marks := not(Even_number_of_Quotation_Marks);
            end;
          end;
        '/':
          begin
            if (Previous_symbol = '/') and Insertability_of_Symbol then
            begin
              Delete(Result.Value, Length(Result.Value) - 1, 2);
              repeat
                Read(File_of_Code, Current_Symbol);
              until (Current_symbol = #13) or Eof(File_of_Code);

              while not(Current_symbol = #10) and not(Eof(File_of_Code)) do
                Read(File_of_Code, Current_Symbol);
            end;
          end;
        '*':
          begin
            if (Previous_symbol = '/') and Insertability_of_Symbol then
            begin
              Delete(Result.Value, Length(Result.Value) - 1, 2);
              repeat
                Read(File_of_Code, Current_Symbol);
              until (Current_symbol = '*') or Eof(File_of_Code);

              while not(Current_symbol = '/') and not(Eof(File_of_Code)) do
                Read(File_of_Code, Current_Symbol);
            end;
          end;
      end;
      Previous_symbol := Current_symbol;
    end;
  until (End_of_Operator_Flag) or Eof(File_of_Code);
  Position_in_file_with_Code := FilePos(File_of_Code);
  closeFile(File_of_Code);
end;

function Check_Symbol_of_End_Operator(Symbol: Char): Boolean;
begin
  case Symbol of
    '{', ';', ':': Result := True;
  else
    Result := False;
  end;
end;

function Check_Symbol_of_Manipulate_Const(Even_number_of_Quotation_Marks, Even_number_of_Single_Quotation_Marks: Boolean; Amount_of_Round_Brackets: Integer): Boolean;
begin
  Result := not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks);
  Result := Result and (Amount_of_Round_Brackets = 0);
end;

function Define_Length_of_SubOperator_in_Operator(const Value_of_Operator: string): Integer;
var
  Amount_of_Round_Brackets: Integer;
  Even_number_of_Single_Quotation_Marks: Boolean;
  Even_number_of_Quotation_Marks: Boolean;
begin
  Even_number_of_Single_Quotation_Marks := False;
  Even_number_of_Quotation_Marks := False;

  if(Copy(Value_of_Operator, 1, 2) = 'if') or (Copy(Value_of_Operator, 1, 6) = 'switch') then
  begin
    Result := 0;
    repeat
      Inc(Result);
    until (Value_of_Operator[Result] = '(');
    Amount_of_Round_Brackets := 1;
    repeat
      Inc(Result);
      case (Value_of_Operator[Result]) of
        '(':
          begin
            if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Inc(Amount_of_Round_Brackets);
          end;
        ')':
          begin
            if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Dec(Amount_of_Round_Brackets);
          end;
        #39:
          Even_number_of_Single_Quotation_Marks := not(Even_number_of_Single_Quotation_Marks);
        #34:
          Even_number_of_Quotation_Marks := not(Even_number_of_Quotation_Marks);
      end;
    until (Amount_of_Round_Brackets = 0);
    if (Copy(Value_of_Operator, 1, 4) = 'case') then
    repeat
      Inc(Result);
      case (Value_of_Operator[Result]) of
        #39:
          begin
            if (Even_number_of_Single_Quotation_Marks) then
              Even_number_of_Single_Quotation_Marks := False
            else
              Even_number_of_Single_Quotation_Marks := True;
          end;
        #34:
          begin
            if (Even_number_of_Quotation_Marks) then
              Even_number_of_Quotation_Marks := False
            else
              Even_number_of_Quotation_Marks := True;
          end;
      end;
    until (Value_of_Operator[Result] = ':') and (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks));
  end
  else
  begin
    Result := 0;
    Amount_of_Round_Brackets := 0;
    repeat
      Inc(Result);
      case (Value_of_Operator[Result]) of
        #39:
          if (Amount_of_Round_Brackets = 0 ) then
            Even_number_of_Single_Quotation_Marks := not(Even_number_of_Single_Quotation_Marks);

        #34:
          if (Amount_of_Round_Brackets = 0 ) then
            Even_number_of_Quotation_Marks := not(Even_number_of_Quotation_Marks);
        '(':
          begin
            if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Amount_of_Round_Brackets := Amount_of_Round_Brackets + 1;
          end;

        ')':
          begin
            if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Amount_of_Round_Brackets := Amount_of_Round_Brackets - 1;
          end;
      end;
    until (Check_Symbol_of_End_Operator(Value_of_Operator[Result])) and
              Check_Symbol_of_Manipulate_Const(Even_number_of_Quotation_Marks, Even_number_of_Single_Quotation_Marks, Amount_of_Round_Brackets);
    if (Value_of_Operator[Result] = '{') then
      Dec(Result);
  end;
end;

procedure Remove_extreme_Curly_Brackets_in_Operator(var Value_of_Operator: string);
var
  Amount_of_Round_Brackets: Integer;
  Amount_of_Curly_Brackets: Integer;
  Even_number_of_Single_Quotation_Marks: Boolean;
  Even_number_of_Quotation_Marks: Boolean;
  Position_of_last_Curly_Bracket: Integer;
  Index: Integer;
begin
  Amount_of_Round_Brackets := 0;
  Amount_of_Curly_Brackets := 1;
  Even_number_of_Single_Quotation_Marks := False;
  Even_number_of_Quotation_Marks := False;
  Index := 1;
  repeat
    Index := Index + 1;
    case Value_of_Operator[Index] of
      #39:
        if (Amount_of_Round_Brackets = 0 ) then
            Even_number_of_Single_Quotation_Marks := not(Even_number_of_Single_Quotation_Marks);
      #34:
        if (Amount_of_Round_Brackets = 0 ) then
          Even_number_of_Quotation_Marks := not(Even_number_of_Quotation_Marks);
      '(':
        begin
          if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
            Amount_of_Round_Brackets := Amount_of_Round_Brackets + 1;
        end;
      ')':
        begin
          if (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
            Amount_of_Round_Brackets := Amount_of_Round_Brackets - 1;
        end;
      '{':
          begin
            if (Amount_of_Round_Brackets = 0) and (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Amount_of_Curly_Brackets := Amount_of_Curly_Brackets + 1;
          end;
      '}':
          begin
            if (Amount_of_Round_Brackets = 0) and (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) then
              Amount_of_Curly_Brackets := Amount_of_Curly_Brackets - 1;
          end;
    end;
  until (Value_of_Operator[Index] = '}') and (Amount_of_Curly_Brackets = 0) and
        (not(Even_number_of_Quotation_Marks or Even_number_of_Single_Quotation_Marks)) and (Amount_of_Round_Brackets = 0);
  Position_of_last_Curly_Bracket := Index;
  Delete(Value_of_Operator, Position_of_last_Curly_Bracket, 1);
  Delete(Value_of_Operator, 1, 1);
end;

function Take_Name_of_Identifier(Description_Identifier: string):string;
var
  RegularExpression: TRegExpr;
  Identifier: string;
begin
  Identifier := '';
  RegularExpression := TRegExpr.Create;
  RegularExpression.InputString := Description_Identifier;
  RegularExpression.Expression := '(\s+)(_|[a-z]|[A-Z])(\w*)(\s*)(=|,|;|\))';
  if (RegularExpression.Exec) then
  begin
    Identifier := RegularExpression.Match[0];
    Delete(Identifier, Length(Identifier), 1);
    while(Identifier[1] = ' ') do
      Delete(Identifier, 1, 1);
    while(Identifier[Length(Identifier)] = ' ') do
      Delete(Identifier, Length(Identifier), 1);
  end;
  RegularExpression.Free;
  Result := Identifier;
end;

function Check_Repeat_of_Local_Params(Name_of_Identifier: string; const List_Identifier: T_List_Identifier): Boolean;
var
  i: Integer;
begin
  Result := True;

  for i := 0 to (Length(List_Identifier) - 1) do
    if(List_Identifier[i].Name = Name_of_Identifier) then
      Result := False;
end;

procedure Add_Identifier_in_List(Description_Identifier: string; var List_Identifier: T_List_Identifier);
var
  Index: Integer;
  Identifier: T_Identifier;
begin
  Identifier.Name := Take_Name_of_Identifier(Description_Identifier);
  Identifier.Count_of_Spen := 0;
  Identifier.Access := True;

  if (Check_Repeat_of_Local_Params(Identifier.Name, List_Identifier)) then
  begin
    Index := Length(List_Identifier);
    SetLength(List_Identifier, Index + 1);
    List_Identifier[Index] := Identifier;
  end;
end;



function Delete_Identifier_from_Operator(Operator: string; Description_Identifier: string):string;
var
  RegularExpression: TRegExpr;
begin
  RegularExpression := TRegExpr.Create;
  RegularExpression.InputString := Description_Identifier;
  RegularExpression.Expression := '(\s+)(_|[a-z]|[A-Z])(\w*)(\s*)(,|;|\))';
  if (RegularExpression.Exec) then
  begin
    Delete(Operator, Pos(RegularExpression.Match[0], Operator), Length(RegularExpression.Match[0]));
  end;
  Result := Operator;
end;

procedure Check_Operator_of_Description_Identifier(Operator: string; var List_Identifier: T_List_Identifier);
var
  Last_Symbol: Char;
  Identifier: T_Identifier;
  RegularExpression: TRegExpr;
begin
  RegularExpression := TRegExpr.Create;
  RegularExpression.InputString := Operator;
  RegularExpression.Expression := '([A-Z]|[a-z])(\w*)((\[\])?)(\s*)((<\w+>)?)(\s+)(_|[a-z]|[A-Z])(\w*)(\s*)(=|,|;|\))';
  if (RegularExpression.Exec) then
  begin
    last_symbol := (RegularExpression.Match[0])[Length(RegularExpression.Match[0])];
    Add_Identifier_in_List(RegularExpression.Match[0], List_Identifier);
    if(last_symbol = ',') then
    begin
      Operator := Delete_Identifier_from_Operator(Operator, RegularExpression.Match[0]);
      Check_Operator_of_Description_Identifier(Operator,List_Identifier);
    end;
  end;
  RegularExpression.Free;
end;

function Add_Subprogramm_to_List(Name_of_Subprogramm: string; var List_of_Subprogramm: T_List_Subprogramm):Integer;
var
  Subprogramm: T_Subprogramm;
  Index: Integer;
begin
  Subprogramm.Name := Name_of_Subprogramm;

  Index := Length(List_of_Subprogramm);
  SetLength(List_of_Subprogramm, Index + 1);
  List_of_Subprogramm[Index] := Subprogramm;

  Result := Index;
end;

function Define_Name_of_Subprogramm(Description_of_Subprogramm: string):string;
var
  RegularExpression: TRegExpr;
  Name_of_Subprogramm: string;
begin
  RegularExpression := TRegExpr.Create;
  RegularExpression.InputString := Description_of_Subprogramm;
  RegularExpression.Expression := '(\s+)(_|[a-z]|[A-Z])(\w*)(\s*)\(';
  if (RegularExpression.Exec) then
  begin
    Name_of_Subprogramm := RegularExpression.Match[0];
    Delete(Name_of_Subprogramm, Length(Name_of_Subprogramm), 1);
    while(Name_of_Subprogramm[1] = ' ') do
      Delete(Name_of_Subprogramm, 1, 1);
    while(Name_of_Subprogramm[Length(Name_of_Subprogramm)] = ' ') do
      Delete(Name_of_Subprogramm, Length(Name_of_Subprogramm), 1);
  end;
  Result := Name_of_Subprogramm;
end;

function Define_Description_of_Local_Params_in_Description_Subprogramm(Description_of_Subprogramm: string):string;
var
  RegularExpression: TRegExpr;
  Description_of_Local_Params: string;
begin
  RegularExpression := TRegExpr.Create;
  RegularExpression.InputString := Description_of_Subprogramm;
  RegularExpression.Expression := '\((.+)\)';
  if (RegularExpression.Exec) then
    Description_of_Local_Params := RegularExpression.Match[0];
  Result := Description_of_Local_Params;
end;

procedure Check_Repeat_of_Local_and_Global_Identifiers(Index_of_Local_Subprogramm: Integer; var List_of_Subprogramm: T_List_Subprogramm);
var
  i, j: Integer;
begin
  for i := 0 to (Length(List_of_Subprogramm[Index_of_Local_Subprogramm].List_Identifier) - 1) do
  begin
    for j := 0 to (Length(List_of_Subprogramm[0].List_Identifier) - 1) do
      if (List_of_Subprogramm[0].List_Identifier[j].Access and
          (List_of_Subprogramm[0].List_Identifier[j].Name = List_of_Subprogramm[Index_of_Local_Subprogramm].List_Identifier[i].Name)) then
        List_of_Subprogramm[0].List_Identifier[j].Access := false;
  end;
end;

function Check_Right_Identifier_in_Operator(Identifier: string; Operator: string; Index_of_Begin_Identifier: Integer): Boolean;
var
  RegularExpression: TRegExpr;
begin
  RegularExpression := TRegExpr.Create;
  RegularExpression.Expression := '\w';

  Result := true;

  if Index_of_Begin_Identifier <> 1 then
  begin
    RegularExpression.InputString := '' + Operator[Index_of_Begin_Identifier - 1];
    if (RegularExpression.Exec) then
      Result := false
  end;

  if ((Index_of_Begin_Identifier + Length(Identifier)) <= Length(Operator)) then
  begin
    RegularExpression.InputString := '' + Operator[Index_of_Begin_Identifier + Length(Identifier)];
    if (RegularExpression.Exec) then
      Result := false
  end;
end;

procedure Calc_Count_of_Statements(Operator: string; var Identifier: T_Identifier);
var
  Even_number_of_Single_Quotation_Marks: Boolean;
  Even_number_of_Quotation_Marks: Boolean;
  i: Integer;
begin
  Even_number_of_Single_Quotation_Marks := true;
  Even_number_of_Quotation_Marks := true;

  for i := 1 to (Length(Operator) - Length(Identifier.Name) + 1) do
  begin
    if((Copy(Operator, i, Length(Identifier.Name)) = Identifier.Name) and (Even_number_of_Quotation_Marks) and  (Even_number_of_Single_Quotation_Marks)) then
      if(Check_Right_Identifier_in_Operator(Identifier.Name, Operator, i)) then
        Inc(Identifier.Count_of_Spen);
    case Operator[i] of
      #39: Even_number_of_Quotation_Marks := not(Even_number_of_Quotation_Marks);
      #34: Even_number_of_Single_Quotation_Marks := not(Even_number_of_Single_Quotation_Marks);
    end;
  end;
end;


procedure Check_Spen_Identifier_in_Operator(Operator: string; Index_of_Local_Subprogramm: Integer; var List_of_Subprogramm: T_List_Subprogramm);
var
  i: Integer;
begin
  for i := 0 to (Length(List_of_Subprogramm[Index_of_Local_Subprogramm].List_Identifier) - 1) do
    Calc_Count_of_Statements(Operator, List_of_Subprogramm[Index_of_Local_Subprogramm].List_Identifier[i]);

  if(Index_of_Local_Subprogramm <> 0) then
  for i := 0 to (Length(List_of_Subprogramm[0].List_Identifier) - 1) do
    if(List_of_Subprogramm[0].List_Identifier[i].Access) then
      Calc_Count_of_Statements(Operator, List_of_Subprogramm[0].List_Identifier[i]);
end;

procedure Delete_Begining_Spaces_in_Code(var Text_of_Code: string);
var
  Count_of_Space, i: Integer;
begin
  Count_of_Space := 0;
  i := 1;
  while (Text_of_Code[i] = ' ') do
  begin
    Inc(Count_of_Space);
    i := i + 1;
  end;

  Delete(Text_of_Code, 1, Count_of_Space);
end;

procedure Set_Access_to_Global_Identifiers(var List_Global_Identifiers: T_List_Identifier);
var
  i: Integer;
begin
  for i := 0 to (Length(List_Global_Identifiers) - 1) do
    if not(List_Global_Identifiers[i].Access) then
      List_Global_Identifiers[i].Access := true;
end;

procedure Define_Spen_in_Subprogramm(Index_of_Current_Subprogramm: Integer; var text_of_Code: string; var List_of_Subprogramm: T_List_Subprogramm);
var
  Current_Operator: string;
begin
  Check_Repeat_of_Local_and_Global_Identifiers(Index_of_Current_Subprogramm, List_of_Subprogramm);

  Delete_Begining_Spaces_in_Code(text_of_Code);

  while(Length(text_of_Code) <> 0) do
  begin
    if(text_of_Code[1] = '{') then
      Remove_extreme_Curly_Brackets_in_Operator(text_of_Code);
    Current_Operator := Copy(text_of_Code, 1, Define_Length_of_SubOperator_in_Operator(text_of_Code));
    Delete(text_of_Code, 1, Length(Current_Operator));
    Check_Operator_of_Description_Identifier(Current_Operator, List_of_Subprogramm[Index_of_Current_Subprogramm].List_Identifier);
    Check_Repeat_of_Local_and_Global_Identifiers(Index_of_Current_Subprogramm, List_of_Subprogramm);
    Check_Spen_Identifier_in_Operator(Current_Operator, Index_of_Current_Subprogramm, List_of_Subprogramm);
    Delete_Begining_Spaces_in_Code(text_of_Code);
  end;

  Set_Access_to_Global_Identifiers(List_of_Subprogramm[0].List_Identifier);
end;

procedure Output_Result_of_Spen(const List_of_Subprogramm: T_List_Subprogramm);
var
  i, j: Integer;
begin
  for i := 0 to (Length(List_of_Subprogramm) - 1) do
  begin
    Writeln('Subprogramm: ', List_of_Subprogramm[i].Name);
    for j := 0 to (Length(List_of_Subprogramm[i].List_Identifier) - 1) do
    begin
      Writeln('   Identifier: ', List_of_Subprogramm[i].List_Identifier[j].Name, '; Spen = ', List_of_Subprogramm[i].List_Identifier[j].Count_of_Spen - 1);
    end;
    Writeln;
  end;
end;

procedure Define_Spen(const Name_of_file_with_Code: string);
var
  File_of_Code: file of Char;
  Position_in_file_with_Code: LongInt;
  Size_of_file_with_Code: LongInt;
  List_of_Subprogramm: T_List_Subprogramm;
  Index_of_Current_Subprogramm_in_List: Integer;
  Current_Operator: T_Operator;
  Description_Subprogramm: string;
  Description_of_Local_Params: string;
begin
  Current_Operator.Value := '';
  Position_in_file_with_Code := 0;

  AssignFile(File_of_Code, Name_of_file_with_Code);
  Reset(File_of_Code);
  Size_of_file_with_Code := FileSize(File_of_Code);
  CloseFile(File_of_Code);

  Add_Subprogramm_to_List('Global', List_of_Subprogramm);


  while (Position_in_file_with_Code <> Size_of_file_with_Code) do
  begin
    Current_Operator := Define_Next_Operator(Name_of_file_with_Code, Position_in_file_with_Code);
    if Current_Operator.Component_Flag then
    begin
      Description_Subprogramm := Copy(Current_Operator.Value, 1, Define_Length_of_SubOperator_in_Operator(Current_Operator.Value));
      Delete(Current_Operator.Value, 1, Length(Description_Subprogramm));
      Index_of_Current_Subprogramm_in_List := Add_Subprogramm_to_List(Define_Name_of_Subprogramm(Description_Subprogramm),List_of_Subprogramm);
      Description_of_Local_Params := Define_Description_of_Local_Params_in_Description_Subprogramm(Description_Subprogramm);
      Check_Operator_of_Description_Identifier(Description_of_Local_Params, List_of_Subprogramm[Index_of_Current_Subprogramm_in_List].List_Identifier);
      Check_Spen_Identifier_in_Operator(Description_of_Local_Params, Index_of_Current_Subprogramm_in_List, List_of_Subprogramm);
      Define_Spen_in_Subprogramm(Index_of_Current_Subprogramm_in_List, Current_Operator.Value, List_of_Subprogramm);
    end
    else
    begin
      Check_Operator_of_Description_Identifier(Current_Operator.Value, List_of_Subprogramm[0].List_Identifier);
      Check_Spen_Identifier_in_Operator(Current_Operator.Value, 0, List_of_Subprogramm);
    end;
  end;

  Output_Result_of_Spen(List_of_Subprogramm);
end;


begin
  Define_Spen('my_java.java');
  Readln;
end.
