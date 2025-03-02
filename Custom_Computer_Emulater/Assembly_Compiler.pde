class Assembly_Compiler
{
  HashMap<String, Short> Indexs = new HashMap<String, Short>();
  Emulator emulator;

  Assembly_Compiler(String file, Emulator e)
  {
    emulator = e;
    String[] Code = loadStrings(file);
    for (int i = 0; i < Code.length; i ++)
      add_code(Code[i].replace((char)9 + "", ""), e);
  }

  void add_code(String c, Emulator e)
  {
    if (c.length() == 0)
      return;
    if (c.charAt(0) == '*')
      return;
    if (c.charAt(0) == ':')
    {
      String not_first_char = c.substring(1, c.length());
      Indexs.put(not_first_char, (short)((code_index - code_start) / 3));
      if (not_first_char.equals("main"))
        emulator.registers[PC] = (short)((code_index - code_start) / 3);
      return;
    }
    //println(c);
    String[] split = c.split(" ");
    short cmd = get_token(tokens, split[0]);
    //print(split[0], cmd, "");
    e.memory[code_index] = cmd;
    if (split.length >= 2)
    {
      memset(true, split[1], e);
      //print(decode(split[1]), split[1], "");
    }
    if (split.length >= 3)
    {
      memset(false, split[2], e);
      //print(decode(split[2]), split[2]);
    }
    if (split.length >= 4)
    {
      e.memory[code_index] |= decode(split[3]) << 10;
      //print(decode(split[3]), split[3]);
    }
    //println();
    code_index += 3;
  }

  void memset(boolean type, String code, Emulator e)
  {
    int first = type ? 6 : 8;
    short value = decode(code);
    e.memory[code_index + (type ? 1 : 2)] = value;
    if (code.charAt(0) == '%')
      e.memory[code_index] |= Register << first;
    if (code.charAt(0) == '*')
      e.memory[code_index] |= Pointer << first;
  }

  short decode(String c)
  {
    if (c.charAt(0) == '%' || c.charAt(0) == '*')
      return get_token(register_tokens, c.substring(1, c.length()));
    short value;
    if (c.charAt(0) == '\'')
      if (c.length() == 1)
        return (int)' ';
      else
        return (short)c.charAt(1);
    if (c.charAt(0) == '0' && c.length() >= 2)
    {
      if (c.charAt(1) == 'b')
        return parse_binary(c.substring(2, c.length()));
      if (c.charAt(1) == 'x')
        return parse_hex(c.substring(2, c.length()));
    }
    if(c.charAt(c.length() - 1) == 'f')
    {
      value = (short)toHalfFloat(Float.parseFloat(c));
      return value;
    }
    try {
      value = (short)Integer.parseInt(c);
    }
    catch(NumberFormatException e) {
      return Indexs.get(c);
    }
    return value;
  }
}

short parse_binary(String s)
{
  short ret = 0;
  for (int i = 0; i < s.length(); i ++)
    ret |= (s.charAt(i) - '0') << i;
  return ret;
}

short parse_hex(String s)
{
  short ret = 0;
  for (int i = s.length() - 1; i >= 0; i --)
    ret |= get_hex(s.charAt(i)) << ((s.length() - 1 - i) * 4);
  return ret;
}

int get_hex(char c)
{
  for (int i = 0; i < 10; i ++)
    if (c - '0' == i)
      return i;
  if (c == 'A') return 10;
  if (c == 'B') return 11;
  if (c == 'C') return 12;
  if (c == 'D') return 13;
  if (c == 'E') return 14;
  if (c == 'F') return 15;
  return -1;
}
