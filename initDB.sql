CREATE DATABASE IF NOT EXISTS pschedule
USE pschedule;

DROP TABLE IF EXISTS performance;
DROP TABLE IF EXISTS time;
DROP TABLE IF EXISTS user;
DROP TABLE IF EXISTS user_bought;
DROP TABLE IF EXISTS event;
DROP TABLE IF EXISTS user_favorite;

CREATE TABLE IF NOT EXISTS event(
                            id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
                            genre VARCHAR(255) NOT NULL,
                            name VARCHAR(255) NOT NULL,
                            url VARCHAR(255),
                            PRIMARY KEY(name),
                            UNIQUE KEY(id)
                          );

CREATE TABLE IF NOT EXISTS performance(
                            name VARCHAR(255) NOT NULL,
                            performance VARCHAR(255) NOT NULL,
                            PRIMARY KEY(name,performance),
                            FOREIGN KEY(name)
                                REFERENCES event(name)
                                ON UPDATE CASCADE
                                ON DELETE CASCADE
                           );

CREATE TABLE IF NOT EXISTS time(
                           day DATETIME NOT NULL,
                           name VARCHAR(255) NOT NULL,
                           special VARCHAR(255),
                           PRIMARY KEY(name, day),
                           FOREIGN KEY(name)
                               REFERENCES event(name)
                               ON UPDATE CASCADE
                               ON DELETE CASCADE
                           ) ;

CREATE TABLE IF NOT EXISTS user (
                            id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
                            name VARCHAR(255) UNIQUE NOT NULL,
                            password VARCHAR(1000) NOT NULL,
                            password_salt VARCHAR(255) NOT NULL,
                            PRIMARY KEY(id)
                           ) ;

CREATE TABLE IF NOT EXISTS user_bought(
                           id INTEGER NOT NULL AUTO_INCREMENT,
                           user_id INTEGER UNSIGNED NOT NULL,
                           event_id INTEGER UNSIGNED NOT NULL,
                           PRIMARY KEY(id),
                           FOREIGN KEY(user_id)
                                   REFERENCES user (id)
                                   ON UPDATE CASCADE
                                   ON DELETE CASCADE,
                           FOREIGN KEY(event_id)
                                   REFERENCES event(id)                                   
                                   ON UPDATE CASCADE
                                   ON DELETE CASCADE
                           ) ;

CREATE TABLE IF NOT EXISTS user_favorite(
                           id INTEGER NOT NULL AUTO_INCREMENT,
                           user_id INTEGER UNSIGNED NOT NULL,
                           event_id INTEGER UNSIGNED NOT NULL,
                           PRIMARY KEY(id),
                           FOREIGN KEY(user_id)
                                   REFERENCES user (id)
                                   ON UPDATE CASCADE
                                   ON DELETE CASCADE,
                           FOREIGN KEY(event_id)
                                   REFERENCES event(id)                                   
                                   ON UPDATE CASCADE
                                   ON DELETE CASCADE
                           ) ;
