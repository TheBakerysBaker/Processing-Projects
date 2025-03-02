class Display extends PApplet
{
  Emulator E;
  int key_index = 0;
  Display(Emulator e)
  {
    super();
    E = e;
    PApplet.runSketch(new String[] {this.getClass().getSimpleName()}, this);
  }

  void settings()
  {
    size(E.memory[variables_start] * 5, E.memory[variables_start + 1] * 5, P2D);
  }

  void setup()
  {
    frameRate(1000);
    noStroke();
    display = createGraphics(width, height);
  }

  void draw()
  {
    //println(frameRate);
    if (E.memory[variables_start + 4] == 1)
    {
      E.memory[variables_start + 4] = 0;
      E.memory[variables_start + 5] = (short)E.keys[0];
      pop_key();
    }
    //loadPixels();
    display.beginDraw();
    display.noStroke();
    int index_G = 0;
    //println(E.memory[variables_start], E.memory[variables_start + 1]);
    for (int p = 0; p < E.memory[variables_start] * E.memory[variables_start + 1]; p ++)
    {
      int[] data = E.get_pixel(index_G);
      for (int i = 0; i < data.length - 1; i ++)
      {
        display.fill(data[i]);
        display.rect(p % E.memory[variables_start] * 5, p / E.memory[variables_start] * 5, 5, 5);
        //p ++;
        //pixels[index_P] = data[i];
      }
      index_G = data[data.length - 1];
    }
    display.endDraw();
    image(display, 0, 0);
    //updatePixels();
  }

  void push_key()
  {
    if (key_index < E.keys.length)
    {
      if((key >= 32 || key <= 256) && keyCode >= 32)
      E.keys[key_index] = (char)key;
      else E.keys[key_index] = (char)keyCode;
      key_index ++;
    }
  }

  void pop_key()
  {
    if (key_index > 0)
      key_index --;
    E.keys[key_index] = 0;
    for (int i = 0; i < key_index - 1; i ++)
      E.keys[i] = E.keys[i+1];
  }

  void keyPressed()
  {
    push_key();
  }
}
