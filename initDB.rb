# coding: utf-8
require 'mysql2'

client = Mysql2::Client.new(host: "localhost",username: "root", password: "")

client.query("CREATE DATABASE pschedule")
client.query("USE pschedule")

#パフォーマンスはわける
client.query("CREATE TABLE event(
                            id INT UNSIGNED NOT NULL AUTO_INCREMENT,
                            time DATETIME NOT NULL,
                            genre VARCHAR(255) NOT NULL,
                            name VARCHAR(255) NOT NULL,
                            url VARCHAR(255) NOT NULL,
                            PRIMARY KEY(id)
                          )")

