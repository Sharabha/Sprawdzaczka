/* Copied and adapted from: http://csclub.uwaterloo.ca/~tmyklebu/happyrun.cc */

/* "Securely" run a program by disallowing the vast majority of system
 * calls.  In particular, programs run by happyrun will be unable to
 * access socket functions, open files for writing, and spawn new processes.
 *
 * This could be enhanced to permit forks and trace forked processes as well;
 * this seems like a massive nuisance, however, so I haven't done it.
 *
 * Tor Myklebust
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdarg.h>

#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/user.h>
#include <sys/syscall.h>
#include <stdio.h>

#include <map>
using namespace std;

#define FORALL(it, st) for (typeof(st.end()) it=st.begin(); it!=st.end(); it++)

// struct x86_linux_regs {
//   int ebx, ecx, edx, esi, edi, ebp, eax, xds, xes, xfs, xgs,
//       orig_eax, eip, xcs, eflags, esp, xss;
// };

struct process;

map<int, process*> pid2process;
int kidpid, debug_level = 10;

void killall() {
  FORALL (it, pid2process)
    kill(it->first, 9);
}

void dbgprintf(int level, char *s, ...) {
  if (debug_level >= level) {
    va_list vargs;
    va_start(vargs, s);
    vfprintf(stderr, s, vargs);
    va_end(vargs);
  }
}

struct process {
  int pid;
  int startup;
  int in_syscall;
  int which_syscall;
  int ok[256];
  process(int pid) {
    this->pid = pid;
    startup = 1;
    in_syscall = 1;
    which_syscall = 0xb;
    // allowed syscalls:
    ok[1] = 1;   // exit
    ok[3] = 1;   // read
    ok[4] = 1;   // write
    ok[6] = 1;   // close
    ok[13] = 1;  // time
    ok[20] = 1;  // getpid
    ok[24] = 1;  // getuid
    ok[27] = 1;  // alarm
    ok[29] = 0;  // pause
    ok[33] = 0;  // access
    ok[42] = 1;  // pipe
    ok[45] = 1;  // brk
    ok[47] = 1;  // getgid
    ok[48] = 1;  // signal
    ok[49] = 1;  // geteuid
    ok[50] = 1;  // getegid
    ok[63] = 1;  // dup2
    ok[64] = 1;  // getppid
    ok[65] = 1;  // getpgrp
    ok[67] = 1;  // sigaction
    ok[90] = 1;  // mmap
    ok[91] = 1;  // munmap
    ok[104] = 1; // setitimer
    ok[122] = 0; // uname
    ok[140] = 1; // llseek
    ok[174] = 1; // rt_sigaction
    ok[197] = 1; // fstat64
    ok[252] = 1; // exit_group
  }

  void process_event(int status) {
    if (WIFEXITED(status)) {
      dbgprintf(2, "Process %i terminated naturally.\n", pid);
      pid2process.erase(pid);
      delete this;
      return;
    }
    
    if (WIFSTOPPED(status)) {
      struct user_regs_struct regs;
      // x86_linux_regs regs;
      if (-1 == ptrace(PTRACE_GETREGS, pid, 0, &regs)) {
        dbgprintf(1,"Oops, terminating %i; ", pid);
        perror("GETREGS: ");
        kill(pid, 9);
        return;
      }
      in_syscall = !in_syscall;

      if (in_syscall) {
        if (regs.orig_eax > 255 || regs.orig_eax < 0) {
          dbgprintf(1,"Terminating %i; bad orig_eax (%8x).\n",
                    pid, regs.orig_eax);
          kill(pid, 9);
          return;
        }
        switch (regs.orig_eax) { // eax holds syscall number but gets mangled
         case 5: // open
          if (regs.ecx & 3) { // write permission requested
            dbgprintf(1,"Terminating %i; asked for write to file\n", pid);
            kill(pid, 9);
            return;
          }
         break;
         default:
          if (!ok[regs.orig_eax]) {
            dbgprintf(1,"Terminating %i; bad syscall %i\n", pid, regs.orig_eax);
            kill(pid, 9);
            return;
          }
         break;
        }
        which_syscall = regs.orig_eax;
      }
      else {
      }
    }

    if (-1 == ptrace(PTRACE_SYSCALL, pid, 0, 0)) {
      dbgprintf(1,"Oops, terminating %i; ", pid);
      perror("SYSCALL: ");
      kill(pid, 9);
      return;
    }
  }
};

void control_shit() {
  while (pid2process.size()) {
    int status;
    int pid = wait(&status);
    if (pid2process.count(pid)) {
      pid2process[pid]->process_event(status);
    }
    else {
      dbgprintf(1,"Received event from unknown process.  Dying.\n");
      printf("PID=%d\n", pid);
      killall();
      exit(0);
    }
  }
}

int main(int argc, char**argv, char**envp) {
  switch (kidpid = fork()) {
   case -1:
    perror("happyrun: fork ");
    exit(-1);
   break;
   case 0:
    if (-1 == ptrace(PTRACE_TRACEME, 0, 0, 0)) {
      perror("happyrun: ptrace ");
      exit(-1);
    }
    execve(argv[1], argv+1, envp);
    perror("happyrun: execve ");
    exit(-1);
   break;
   default:
    pid2process[kidpid] = new process(kidpid);
    control_shit();
   break;
  } 
  kill(kidpid, 9);
}
