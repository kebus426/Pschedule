# coding: utf-8
require 'mysql2'

client = Mysql2::Client.new(host: "localhost",username: "root", password: "")

#client.query("CREATE DATABASE pschedule")
client.query("USE pschedule")

#パフォーマンスはわける
client.query("DROP TABLE performance")
client.query("DROP TABLE time")
client.query("DROP TABLE event")

client.query("CREATE TABLE event(
                            genre VARCHAR(255) NOT NULL,
                            name VARCHAR(255) NOT NULL,
                            url VARCHAR(255),
                            PRIMARY KEY(name)
                          )")

client.query("CREATE TABLE performance(
                            name VARCHAR(255) NOT NULL,
                            performance VARCHAR(255) NOT NULL,
                            PRIMARY KEY(name,performance),
                            FOREIGN KEY(name)
                                REFERENCES event(name)
                                ON UPDATE CASCADE
                                ON DELETE CASCADE
                           )")

client.query("CREATE TABLE time(
                           day DATETIME NOT NULL,
                           name VARCHAR(255) NOT NULL,
                           special VARCHAR(255),
                           PRIMARY KEY(name, day),
                           FOREIGN KEY(name)
                               REFERENCES event(name)
                               ON UPDATE CASCADE
                               ON DELETE CASCADE
                           )")
