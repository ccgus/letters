#include <stdio.h>
#include "mnemonic.h"

main ()
{
  char buf[0x90000];
  mn_byte outbuf[0x10000];
  int buflen;
  int n;

  buflen = fread (buf, 1, sizeof buf - 1, stdin);
  buf[buflen] = 0;

  n = mn_decode (buf, outbuf, sizeof outbuf);
  if (n < 0)
    fprintf (stderr, "mn_decode result %d\n", n);
  else 
    fwrite (outbuf, 1, n, stdout);

  return 0;
}
