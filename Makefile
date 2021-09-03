
DB_HOST:=127.0.0.1
DB_PORT:=3306
DB_USER:=
DB_PASS:=
DB_NAME:=
SLOW_QUERY_LOG:=/tmp/mysql-slow.sql

PROJECT_ROOT=/home/isucon/webapp
BUILD_DIR=$(PROJECT_ROOT)/go
BIN_NAME=isucondition
SERVICE=isucondition.go.service

.PHONY: build
build:
	cd $(BUILD_DIR); \
	go build -o $(BIN_NAME) main.go; \
	sudo systemctl restart $(SERVICE);

# make settingfile_to_git FILE=/etc/nginx/nginx.conf
# mysqld.cnfはシンボリックリンクでは機能しないので注意！！ sudo ln -s $(SETTINGDIR)/$${FILE##*/} $(FILE)
SETTINGDIR=$(PROJECT_ROOT)/setting
FILE=
.PHONY: settingfile_to_git
settingfile_to_git:
	mkdir -p $(SETTINGDIR)
	sudo cp $(FILE) $(SETTINGDIR)/$${FILE##*/}
	sudo rm $(FILE)
	sudo ln $(SETTINGDIR)/$${FILE##*/} $(FILE)

.PHONY: mysql
mysql:
	mysql -h$(DB_HOST) -P$(DB_PORT) -u$(DB_USER) -p$(DB_PASS) $(DB_NAME)

.PHONY: log
log: 
	sudo journalctl -u $(SERVICE) -n10 -f


.PHONY: pprof
pprof:
	go tool pprof -http=0.0.0.0:8080 $(BUILD_DIR)/$(BIN_NAME) -source_path=$(BUILD_DIR) http://localhost:6060/debug/pprof/profile

.PHONY: myprofiler
myprofiler:
	myprofiler -host=$(DB_HOST) -user=$(DB_USER) -password=$(DB_PASS) -port=$(DB_PORT) -delay=10 -top=30

.PHONY: myprofiler_istall
myprofiler_istall:
	mkdir $(PROJECT_ROOT)/myprofiler_istall
	cd $(PROJECT_ROOT)/myprofiler_istall; \
	wget https://raw.githubusercontent.com/KLab/myprofiler/master/myprofiler.go;\
	go mod init example.com/m;\
	go mod tidy;\
	go build -o myprofiler myprofiler.go;\
	sudo mv myprofiler /usr/local/bin/
	cd $(PROJECT_ROOT)
	rm -r $(PROJECT_ROOT)/myprofiler_istall

# wget https://github.com/KLab/myprofiler/releases/download/0.2/myprofiler.linux_amd64.tar.gz
# tar xf myprofiler.linux_amd64.tar.gz
# rm myprofiler.linux_amd64.tar.gz
# sudo mv myprofiler /usr/local/bin/
# sudo chmod +x /usr/local/bin/myprofiler

	
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

.PHONY: alp_install
alp_install:
	sudo apt install unzip
	wget https://github.com/tkuchiki/alp/releases/download/v1.0.3/alp_linux_amd64.zip
	unzip alp_linux_amd64.zip
	sudo install alp /usr/local/bin/alp
	rm alp_linux_amd64.zip alp

ALPSORT=sum
ALPM="/api/isu/.+/icon,/api/isu/.+/graph,/api/isu/.+/condition,/api/isu/[-a-z0-9]+,/api/condition/[-a-z0-9]+,/api/catalog/.+,/api/condition\?,/isu/........-....-.+"
OUTFORMAT=count,2xx,method,uri,min,max,sum,avg,p99
.PHONY: alp
alp:
	sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q
.PHONY: alpsave
alpsave:
	sudo alp ltsv --file=/var/log/nginx/access.log --pos /tmp/alp.pos --dump /tmp/alp.dump --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q
.PHONY: alpload
alpload:
	sudo alp ltsv --load /tmp/alp.dump --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -q
	
