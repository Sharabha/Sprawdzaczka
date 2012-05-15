#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/user.h>
#include <sys/syscall.h>
#include <stdio.h>

extern const char * syscall_to_str(int syscall);

int main()
{
  pid_t child;
  const int long_size = sizeof(long);
  //tworzymy proces potomny
  child = fork();
  if(child == 0) {
    //jestesmy w procesie potomnym, bo pid = 0
    //informacja dla jądra że jesteśmy śledzeni
    ptrace(PTRACE_TRACEME, 0, NULL, NULL);
    //proces potomny "staje się" programem dummy1
    execl("./dummy1", "dummy1", NULL);
  }
  else {
    //jestesmy w procesie-rodzicu, child - pid dziecka
    //zmienna status będzie trzymała inforamcje o statusie dziecka
    int status;
    //struktura zdefiniowana w sys/user.h
    //sluzy do przechowywania adresow rejestrow procesu
    struct user_regs_struct regs;
    int start = 0;
    long ins;
    while(1) {
      //czekamy az jadra nie da znaku, ze proces potomny chce uzyc
      //wywolania systemowego lub wlasnie skonczyl to robic.
      //Jezeli do tego dojdzie w zmiennej status znajduje sie informacja
      //czego dokladnie proces potomny chce
      wait(&status);
      //w przypadku, gdy proces potomny wychodzi z przerwania systemowego
      //proces-rodzic konczy prace (chociaz moglby dzialac dalej)
      if(WIFEXITED(status))
        {
          printf("Child process exited, exiting too.\n");
          break;
        }
      //w przeciwnym przypadku (proces potomny chce wywolac przerwanie)
      //pobieramy adresy rejestrow procesu potomnego
      ptrace(PTRACE_GETREGS, child, NULL, &regs);
      if(start == 1) {
        //czytamy i wyswietlamy wartosci wybranego rejestru procesu potomnemgo
        //nie do konca rozumiem co to jest, grunt ze pochodzi z procesu potomnego
        //na tej samej zasadzie mozemy kazac mu wywolac inne niz chcial system calle
        //modyfikowac jego dzialanie itd. Mozliwych do wykonania akcji jest dosc duzo
        ins = ptrace(PTRACE_PEEKTEXT, child, regs.eip, NULL);
        printf("EIP: %lx Instruction executed: %lx\n", regs.eip, ins);
        ptrace(PTRACE_PEEKTEXT, child, regs.eax, &ins);
        printf("EAX: %lx Instruction executed: %lx\n", regs.eax, ins);

      }

      if (regs.orig_eax == SYS_open)
        {
          if (regs.ecx & 3) { // write permission requested
            printf("Terminating: asked for write to file\n");
            ptrace(PTRACE_KILL, child, NULL, NULL);
            return;
          }
        }
      
      int ok = 0;
      if ((regs.orig_eax == SYS_open) ||
          (regs.orig_eax == SYS_close) ||
          (regs.orig_eax == SYS_brk)||
          (regs.orig_eax == SYS_mmap) ||
          (regs.orig_eax == SYS_munmap) ||
          (regs.orig_eax == SYS_getpid) ||
          (regs.orig_eax == SYS_getuid) ||
          (regs.orig_eax == SYS_alarm) ||
          (regs.orig_eax == SYS_pause) ||
          (regs.orig_eax == SYS_getgid) ||
          (regs.orig_eax == SYS_signal) ||
          (regs.orig_eax == SYS_setitimer) ||
          (regs.orig_eax == SYS_fstat64) ||
          (regs.orig_eax == SYS_exit_group) ||
          (regs.orig_eax == SYS_execve) ||
          (regs.orig_eax == SYS_mmap2) ||
          (regs.orig_eax == SYS_access) ||
          (regs.orig_eax == SYS_stat64) ||
          (regs.orig_eax == SYS_read) ||
          (regs.orig_eax == SYS_mprotect) ||
          (regs.orig_eax == SYS_set_thread_area) ||
          (regs.orig_eax == SYS_write))
        {
          ok = 1;
        }

      if (!ok)
        {
          printf("Terminating: invalid signall, %s\n", syscall_to_str(regs.orig_eax));
          ptrace(PTRACE_KILL, child, NULL, NULL);
          return;
        }
          
      ptrace(PTRACE_SYSCALL, child, NULL, NULL);
      printf("PTRACE_SYSCALL: %s\n", syscall_to_str(regs.orig_eax));

    }
  }
  return 0;
}

