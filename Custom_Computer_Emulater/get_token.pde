short get_token(String[] list, String target)
{
  for (short i = 0; i < list.length; i ++)
  {
    if (target.equals(list[i]))
    {
      return i;
    }
  }
  return -1;
}
