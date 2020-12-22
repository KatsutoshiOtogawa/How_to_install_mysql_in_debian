
echo grub-pc hold | dpkg --set-selections
apt update && apt upgrade -y

apt -y install git 

# enabla ufw.
systemctl enable ufw
systemctl start ufw

# ufw 有効化のためインストール
# expectは内部処理に癖があるため、pexpectを使う。
apt install -y expect
apt install -y python3-pip
pip3 install pexpect
python3 << END
import pexpect
prc = pexpect.spawn("ufw enable")
prc.expect("Command may disrupt existing ssh connections. Proceed with operation")
prc.sendline("y")
prc.expect( pexpect.EOF )
END

ufw allow 22
# port forwarding mariadb port 3306.
ufw allow 3306

# port forwarding mysql-shell port 33060
ufw allow 33060

# reload firewall settings.
ufw reload

apt-get -y install mariadb-server

systemctl enable mariadb
systemctl start mariadb

MYSQL_ROOT_PASSWORD="elg5nuZsbahm0,bpxixO"

python3 << END
import pexpect
password = "$MYSQL_ROOT_PASSWORD"
shell_cmd = "/usr/bin/mysql_secure_installation"
prc = pexpect.spawn('/bin/bash', ['-c', shell_cmd],timeout=120)
prc.expect("Enter current password for root")
prc.sendline("")

prc.expect("Set root password")
prc.sendline("Y")

prc.expect("New password")
prc.sendline(password)

prc.expect("Re-enter new password")
prc.sendline(password)

prc.expect("Remove anonymous users")
prc.sendline("Y")

prc.expect("Disallow root login remotely")
prc.sendline("Y")

prc.expect("Remove test database and access to it")
prc.sendline("Y")

prc.expect("Reload privilege tables now")
prc.sendline("Y")

prc.expect( pexpect.EOF )
END

# CREATE ROLE DBADMIN.
# this role has all priviledge except Server administration inpacting database system.
# see official document.[Mysql oracle document](https://dev.mysql.com/doc/refman/5.7/en/privileges-provided.html)
mysql << END
CREATE ROLE dbadmin;
GRANT ALL PRIVILEGES ON *.* TO dbadmin;
REVOKE CREATE TABLESPACE,CREATE USER,SHUTDOWN,SUPER,PROCESS,REPLICATION SLAVE,RELOAD ON *.* FROM dbadmin;
END

# CREATE USER connecting from local network.
MYSQL_USER=user1
MYSQL_USER_PASSWORD="28gwZmjjbfpMmzd@tigm"
mysql << END
-- if you are in production environement, you use username@host_ip/netmask. 
-- see official document [mysql oracle document](https://dev.mysql.com/doc/refman/8.0/en/account-names.html)
CREATE USER $MYSQL_USER IDENTIFIED BY '$MYSQL_USER_PASSWORD';
GRANT dbadmin TO $MYSQL_USER;
END



# # install postgresql dataafile and clustor to /var/lib/pgsql/data
# su - postgres -c 'pg_ctl initdb'

# # update postgresql use memory,postgresql_log,style
# sed -i 's/^shared_buffers.*$/shared_buffers = 1024MB                 # min 128kB/' /var/lib/pgsql/data/postgresql.conf
# sed -i "s/^log_filename.*$/log_filename = 'postgresql-%Y-%m-%d.log'    # log file name pattern,/" /var/lib/pgsql/data/postgresql.conf

# echo "===> you want to "

# echo "you CREATE DATABASE dependending your locale data, you use these options"
# echo "LC_COLLATE [=] lc_collate"
# echo "LC_CTYPE [=] lc_ctype" 

cat << END >> ~/.bash_profile
# reference from [postgrsql tutorial](https://www.postgresqltutorial.com/postgresql-sample-database/)
# if you need ER diagram,
# curl -o printable-postgresql-sample-database-diagram.pdf -L https://sp.postgresqltutorial.com/wp-content/uploads/2018/03/printable-postgresql-sample-database-diagram.pdf
function enable_sampledatabase () {
    mkdir \$HOME/sample
    local backdir=\$(pwd)
    cd \$HOME/sample

    wget https://downloads.mysql.com/docs/world.sql.gz
    gzip -d world.sql.gz
    mysql < world.sql

    wget https://downloads.mysql.com/docs/world_x-db.tar.gz
    tar zxvf world_x-db.tar.gz
    cd world_x-db
    # this sample doesnt load mariadb,but mysql is collect.
    # mysql is not supporting 'STORED NOT NULL'
    # reference from [](https://yakst.com/ja/posts/3836)
    mysql < world_x.sql
    cd ../

    wget https://downloads.mysql.com/docs/sakila-db.tar.gz
    tar zxvf sakila-db.tar.gz
    cd sakila-db
    mysql < sakila-schema.sql
    mysql < sakila-data.sql
    cd ../

    wget https://downloads.mysql.com/docs/menagerie-db.tar.gz
    tar zxvf menagerie-db.tar.gz
    cd menagerie-db
    mysql -e 'CREATE DATABASE menagerie;'
    mysql menagerie < cr_pet_tbl.sql
    mysql menagerie < load_pet_tbl.sql
    mysqlimport --local menagerie pet.txt
    mysql menagerie < ins_puff_rec.sql
    mysql menagerie < cr_event_tbl.sql
    mysqlimport --local menagerie event.txt
    cd ../

    # install 
    git clone --depth 1 https://github.com/datacharmer/test_db.git
    cd test_db 
    mysql < employees.sql

    cd $backdir
    rm -rf \$HOME/sample

}

function disable_sampledatabase () {
    # drop dvd_rental database.
    mysql << EOF
    DROP DATABASE IF EXISTS employees;
    DROP DATABASE IF EXISTS menagerie;
    DROP DATABASE IF EXISTS sakila;
    DROP DATABASE IF EXISTS world;
EOF
}

END


# erase fragtation funciton. this function you use vagrant package.
cat << END >> ~/.bash_profile
# eraze fragtation.
function defrag () {
    dd if=/dev/zero of=/EMPTY bs=1M; rm -f /EMPTY
}
END

echo "finish install!"

reboot
