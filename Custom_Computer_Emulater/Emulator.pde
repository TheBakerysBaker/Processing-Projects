class Emulator extends Thread
{

  short[] registers = new short[16];
  long ALU = 0;
  boolean CARRY, ZERO;
  short[] memory = new short[65536];
  boolean Halt = false;
  char[] keys = new char[32];
  boolean print = false;


  Emulator(short w, short h)
  {
    memory[variables_start] = w;
    memory[variables_start + 1] = h;
    memory[variables_start + 2] = RGB_L;
    memory[variables_start + 3] = (short)(random(1 << 16));
    registers[SP] = stack_length-1;
  }

  void do_print(boolean t)
  {
    print = t;
  }

  color[] BW_L(int index)
  {
    int mem = memory[index + graphics_start];
    return new color[]{color(map(mem & 0xff00, 0, (1<<8) - 1, 0, 255)), color(map(mem & 0x00ff, 1<<8, (1<<16) - 1, 0, 255))};
  }
  color[] RGB_L(int index)
  {
    int mem = memory[index + graphics_start];
    int r = (mem >> 10) & ((1<<6) - 1);
    int g = (mem >> 4) & ((1<<6) - 1);
    int b = (mem & ((1<<4) - 1));
    return new color[]{color(map(r, 0, (1<<6) - 1, 0, 255), map(g, 0, (1<<6) - 1, 0, 255), map(b, 0, (1<<4) - 1, 0, 255))};
  }

  int[] get_pixel(int index)
  {
    color[] colors = new color[1];
    int[] data;
    switch(memory[variables_start + 2])
    {
    case BW_L:
      colors = BW_L(index);
    case RGB_L:
      colors = RGB_L(index);
    }
    data = new int[colors.length + 1];
    arrayCopy(colors, data);
    data[data.length - 1] = index + colors.length;
    return data;
  }

  void run(int run_time)
  {
    for (int i = 0; i < run_time; i ++)
    {
      execute();
    }
  }

  void run()
  {
    while (!Halt)
    {
      execute();
    }
  }

  void print_line(int cmd, int t1, int v1, int t2, int v2)
  {
    print(short_to_int(registers[PC]) * 3 + code_start, tokens[cmd], "");
    print_token(t1, v1);
    print_token(t2, v2);
  }

  short get_pointer(short p)
  {
    return memory[short_to_int(p)];
  }
  void set_pointer(short p, short v)
  {
    memory[short_to_int(p)] = v;
  }

  void print_token(int type, int val)
  {
    if (type == Register)
      print(register_tokens[val], "");
    if (type == Literal)
      print("L"+val, "");
    if (type == Pointer)
      print(register_tokens[val], registers[val], ":", get_pointer(registers[val]), "");
  }

  short get_value(int type, int val)
  {
    switch(type)
    {
    case Register:
      return registers[val];
    case Literal:
      return (short)val;
    case Pointer:
      return get_pointer(registers[val]);
    }
    return -1;
  }

  void execute()
  {
    int index = ((1 << bits) - 1) & (short_to_int(registers[PC]) * 3 + code_start);
    int m1 = memory[index];
    int cmd =       (m1 & 0b0000000000111111);
    int val1_type = (m1 & 0b0000000011000000) >> 6;
    int val2_type = (m1 & 0b0000001100000000) >> 8;
    int reg =       (m1 & 0b1111110000000000) >> 10;
    int val1 =      memory[index + 1];
    int val2 =      memory[index + 2];
    //for(int i = 0; i < registers.length; i ++)
    //print((registers[i]) + " ");
    //println();
    if (print)
      print_line(cmd, val1_type, val1, val2_type, val2);
    short A = get_value(val1_type, val1);
    short B = get_value(val2_type, val2);
    short jump_to = (short)(A - 1);
    if (print)
      println(register_tokens[reg], "               ", "A:", A, "B:", B);
    switch(cmd)
    {
    case halt:
      Halt = true;
      break;
    case move:
      if (val2_type == Register)
        registers[val2] = A;
      if (val2_type == Literal)
        memory[val2] = A;
      if (val2_type == Pointer)
        set_pointer(registers[val2], A);
      break;
    case compare:
      ALU = short_to_int(A) - short_to_int(B);
      ZERO = ALU == 0;
      CARRY = short_to_int(A) < short_to_int(B);
      break;
    case jump:
      registers[PC] = jump_to;
      break;
    case jumpG: // JUMP greater
      if (!CARRY && !ZERO)
        registers[PC] = jump_to;
      break;
    case jumpGE: // JUMP greater or equals
      if (!CARRY || ZERO)
        registers[PC] = jump_to;
      break;
    case jumpL: // JUMP less
      if (CARRY && !ZERO)
        registers[PC] = jump_to;
      break;
    case jumpLE: // JUMP less or equals
      if (CARRY || ZERO)
        registers[PC] = jump_to;
      break;
    case jumpE: // JUMP equals
      if (ZERO)
        registers[PC] = jump_to;
      break;
    case jumpNE: // JUMP not equals
      if (!ZERO)
        registers[PC] = jump_to;
      break;
    case add:
      registers[reg] = (short)(A + B);
      break;
    case sub:
      registers[reg] = (short)(A - B);
      break;
    case mult:
      registers[reg] = (short)(A * B);
      break;
    case div:
      registers[reg] = (short)(A / B);
      break;
    case and:
      registers[reg] = (short)(A & B);
      break;
    case or:
      registers[reg] = (short)(A | B);
      break;
    case xor:
      registers[reg] = (short)(A ^ B);
      break;
    case not:
      registers[val2] = (short)(~A);
      break;
    case bsl:
      registers[reg] = (short)(A << B);
      break;
    case bsr:
      registers[reg] = (short)(A >> B);
      break;
    case push:
      set_pointer(registers[SP], A);
      registers[SP] --;
      break;
    case pop:
      registers[SP] ++;
      if (val1_type == Register)
        registers[val1] = memory[short_to_int(registers[SP])];
      if (val1_type == Pointer)
        memory[registers[val1]] = memory[short_to_int(registers[SP])];
      break;
    case call:
      memory[short_to_int(registers[SP])] = registers[PC];
      registers[SP] --;
      registers[PC] = jump_to;
      break;
    case ret:
      registers[SP] ++;
      registers[PC] = memory[short_to_int(registers[SP])];
      break;
    case mod:
      registers[reg] = (short)(short_to_int(A) % short_to_int(B));
      break;
    case addF:
      float sum = toBigFloat(A) + toBigFloat(B);
      registers[reg] = (short)fromFloat(sum);
      break;
    case subF:
      sum = toBigFloat(A) - toBigFloat(B);
      registers[reg] = (short)fromFloat(sum);
      break;
    case multF:
      sum = toBigFloat(A) * toBigFloat(B);
      registers[reg] = (short)fromFloat(sum);
      break;
    case divF:
      sum = toBigFloat(A) / toBigFloat(B);
      registers[reg] = (short)fromFloat(sum);
      break;
    case compareF:
      ZERO = toBigFloat(A) - toBigFloat(B) == 0;
      CARRY = toBigFloat(A) < toBigFloat(B);
      break;
    case FtoI:
      if (val2_type == Register)
        registers[val2] = (short)toBigFloat(A);
      if (val2_type == Pointer)
        memory[registers[val2]] = (short)toBigFloat(A);
      break;
    case ItoF:
      if (val2_type == Register)
        registers[val2] = (short)toHalfFloat((float)A);
      if (val2_type == Pointer)
        memory[registers[val2]] = (short)toHalfFloat((float)A);
        //println(toBigFloat((short)toHalfFloat((float)A)));
      break;
    }
    registers[PC] ++;
  }
}
