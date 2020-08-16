export GO111MODULE=on
DB_HOST:=127.0.0.1
DB_PORT:=3306
DB_USER:=
DB_PASS:=
DB_NAME:=
SLOW_QUERY_LOG:=/tmp/mysql-slow.sql

PROJECT_ROOT=/home/isucon/isucari
BUILD_DIR=$(PROJECT_ROOT)/webapp/go
BIN_NAME=isucari
SERVICE=isucari.golang

SETTING=./setting
FILE=
.PHONY: settingfile_to_git
settingfile_to_git:
	mkdir -p $(OUTDIR)
	sudo cp $(FILE) $(OUTDIR)/$${FILE##*/}
	sudo rm $(FILE)
	sudo ln -s $(OUTDIR)/$${FILE##*/} $(FILE)

.PHONY: mysql
mysql:
	mysql -h$(DB_HOST) -P$(DB_PORT) -u$(DB_USER) -p$(DB_PASS) $(DB_NAME)

.PHONY: log
log: 
	sudo journalctl -u $(SERVICE) -n10 -f


.PHONY: pprof
pprof:
	go tool pprof -http=localhost:8080 $(BUILD_DIR)/$(BIN_NAME) -source_path=$(BUILD_DIR) http://localhost:6060/debug/pprof/profile

.PHONY: myprofiler
myprofiler:
	myprofiler -host=$(DB_HOST) -user=$(DB_USER) -password=$(DB_PASS) -port=$(DB_PORT) -delay=10 -top=30

.PHONY: myprofiler_istall
myprofiler_istall:
	wget https://github.com/KLab/myprofiler/releases/download/0.2/myprofiler.linux_amd64.tar.gz
	tar xf myprofiler.linux_amd64.tar.gz
	rm myprofiler.linux_amd64.tar.gz
	sudo mv myprofiler /usr/local/bin/
	sudo chmod +x /usr/local/bin/myprofiler
	
.PHONY: slowquerylog
slowquerylog:
	mysqldumpslow -s t $(SLOW_QUERY_LOG)
	
.PHONY: slowquerylog_edit
slowquerylog_edit:
	sudo vim /etc/mysql/my.cnf
	
.PHONY: slowquerylog_clear
slowquerylog_clear:
	sudo systemctl stop mysql
	sudo mv $(SLOW_QUERY_LOG) $(SLOW_QUERY_LOG)_copy
	sudo systemctl start mysql
