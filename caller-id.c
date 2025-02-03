#include <errno.h>
#include <fcntl.h>
#include <mosquitto.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/stat.h>
#include <termios.h>
#include <unistd.h>

#define MAX_EVENTS 10

int mqtt_fd = -1;
int epollfd = -1;

int publish(struct mosquitto *mosq, const char *topic, const void *payload, int qos, bool retain) {
  return mosquitto_publish(mosq, NULL, topic, strlen(payload), payload, qos, retain);
}

void modem_tx(int fd, const char *msg) {
  write(fd, msg, strlen(msg));
}

void monitor_fd(int epollfd, int fd, const char *errmsg) {
  struct epoll_event ev;
  ev.events = EPOLLIN | EPOLLRDHUP;
  ev.data.fd = fd;
  if (epoll_ctl(epollfd, EPOLL_CTL_ADD, fd, &ev)) {
    perror(errmsg);
    _exit(3);
  }
}

void connected(struct mosquitto*, void*, int) {
  puts("connected");
}

void disconnected(struct mosquitto*, void*, int) {
  puts("disconnected");
  mqtt_fd = -1;
  exit(1);
}

int main(int argc, char **argv) {
  char *modem = NULL;
  char *mqtt_user = NULL;
  char *mqtt_pw = NULL;
  char *mqtt_server = NULL;
  uint16_t mqtt_port = 1883;
  int opt;

  while ((opt = getopt(argc, argv, "m:u:p:s:P:")) != -1) {
    switch (opt) {
    case 'm':
      modem = optarg;
      break;
    case 'u':
      mqtt_user = optarg;
      break;
    case 'p':
      mqtt_pw = getenv(optarg);
      break;
    case 's':
      mqtt_server = optarg;
      break;
    case 'P':
      mqtt_port = strtol(optarg, NULL, 10);
      break;
    }
  }
  if (mosquitto_lib_init() != MOSQ_ERR_SUCCESS) {
    puts("cant init mqtt");
    return 1;
  }

  struct mosquitto *mqtt = mosquitto_new("caller-id-server", true, NULL);
  if (!mqtt) {
    puts("cant make new mqtt instance");
    return 2;
  }

  mosquitto_connect_callback_set(mqtt, connected);
  mosquitto_disconnect_callback_set(mqtt, disconnected);

  if (mosquitto_username_pw_set(mqtt, mqtt_user, mqtt_pw) != MOSQ_ERR_SUCCESS) {
    puts("cant set user/pw");
    return 3;
  }

  char *will = "disconnected";
  mosquitto_will_set(mqtt, "caller-id/status", strlen(will), will, 0, true);

  int attempts = 10;
  while (attempts-- > 0) {
    if (mosquitto_connect(mqtt, mqtt_server, mqtt_port, 60) != MOSQ_ERR_SUCCESS) {
      puts("unable to connect to mqtt server, retrying in 10");
      sleep(10);
    } else {
      break;
    }
  }

  if (publish(mqtt, "caller-id/status", "starting", 0, true) != MOSQ_ERR_SUCCESS) {
    puts("cant publish status msg");
    return 5;
  }

  int modem_fd = open(modem, O_RDWR | O_NOCTTY | O_NONBLOCK);
  if (modem_fd < 0) {
    perror("cant open modem");
    return 10;
  }

  struct termios options;
  tcgetattr(modem_fd, &options);
  printf("before c_cflag: %x\n", options.c_cflag);

  options.c_cflag = B115200 | CS8 | CREAD | HUPCL | CLOCAL;
  options.c_iflag |= IGNCR;

  options.c_lflag &= ~(ISIG | ICANON | ECHO | ECHOE | ECHOK | ECHOCTL | ECHOKE);

  tcsetattr(modem_fd, TCSANOW, &options);

  epollfd = epoll_create1(0);
  if (epollfd < 0) {
    puts("cant start epoll");
    return 6;
  }

  mqtt_fd = mosquitto_socket(mqtt);
  monitor_fd(epollfd, mqtt_fd, "mqtt socket");
  monitor_fd(epollfd, modem_fd, "modem");

  publish(mqtt, "caller-id/status", "started", 0, true);

  modem_tx(modem_fd, "AT#CID=1\n");

  while (true) {
    struct epoll_event events[MAX_EVENTS];
    int nfds = epoll_wait(epollfd, events, MAX_EVENTS, 1000 * 60);
    if ((nfds == -1) && (errno == EINTR)) continue;
    if (nfds < 0) {
      printf("%d ", nfds);
      perror("epoll_wait failed");
      return 5;
    }
    if (mqtt_fd > 0) {
      mosquitto_loop_misc(mqtt);
    }
    for (int i=0; i < nfds; i++) {
      if (events[i].data.fd == modem_fd) {
        usleep(50000);
        char buffer[1024];
        int size = read(modem_fd, buffer, 1020);
        buffer[size] = 0;
        mosquitto_publish(mqtt, NULL, "caller-id/event", size, buffer, 0, false);
      } else if (events[i].data.fd == mqtt_fd) {
        if (mqtt_fd > 0) {
          mosquitto_loop_read(mqtt, 1);
        }
        if (mqtt_fd > 0) {
          mosquitto_loop_write(mqtt, 1);
        }
      }
    }
  }

  return 0;
}
