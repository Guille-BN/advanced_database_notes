from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    DateTime,
    func
)

from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()

class Team(Base):
    __tablename__ = "teams"

    id = Column(Integer, primary_key=True)
    name = Column(String(50), nullable=False, unique=True)
    description = Column(String(200))
    created_at = Column(DateTime, server_default=func.current_timestamp())

    users = relationship("User", back_populates="team")

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    username = Column(String(50), nullable=False, unique=True)
    email = Column(String(100), nullable=False)
    full_name = Column(String(100))
    team_id = Column(Integer, ForeignKey("teams.id"))
    created_at = Column(DateTime, server_default=func.current_timestamp())

    team = relationship("Team", back_populates="users")
    tasks = relationship("Task", back_populates="assignee")
    comments = relationship("Comment", back_populates="user")

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True)
    title = Column(String(200), nullable=False)
    description = Column(String(1000))
    status = Column(String(20), default="open")
    assigned_to = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, server_default=func.current_timestamp())
    updated_at = Column(DateTime)

    assignee = relationship("User", back_populates="tasks")

    comments = relationship(
        "Comment",
        back_populates="task",
        cascade="all, delete"
    )

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)
    task_id = Column(Integer, ForeignKey("tasks.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(String(1000), nullable=False)
    created_at = Column(DateTime, server_default=func.current_timestamp())

    task = relationship("Task", back_populates="comments")
    user = relationship("User", back_populates="comments")

-- Exercise 1
-- 1. What relationships should Comment have?
/*
A comment should belong to one task and one user, because each comment is made by a user on a specific task.
*/

-- 2. Should Task have a comments relationship?
/*
Yes, because it makes it easier to get all the comments related to a task without writing extra queries.
*/

-- 3. What should happen to comments when a task is deleted?
/*
The comments related to that task should also be deleted, because they would not make sense without the task.
*/


-- Exercise 2
-- 1. What does upgrade() do?
/*
It applies the new migration changes and updates the database to the newest version.
*/

-- 2. What does downgrade() do?
/*
It reverses the migration changes and returns the database to a previous version.
*/

--3. What happens if you downgrade this migration?
/*
The changes made by the migration are removed, like deleting the new table or column that was added.
*/


-- Exercise 4
-- 1. What happens to the column?
/*
The column gets removed from the table.
*/

-- 2. What happens to the data?
/*
All the data stored in that column is lost when the column is deleted.
*/


-- Exercise 5
-- 1. Why use ORM instead of raw SQL?
/*
Because it is easier to read and write code using objects instead of writing SQL queries all the time.
*/

-- 2. Why use migrations?
/*
Because they help keep track of database changes and make it easy to update or rollback versions.
*/

-- 3. When would you rollback?
/*
When a migration causes problems or breaks something in the application and you need to return to the previous version.
*/

-- 4. Difference between add() and commit()?
/*
add() prepares the object to be saved, while commit() actually saves the changes into the database.
*/

-- 5. Why are relationships useful?
/*
Because they make it easier to connect and access related data between tables without writing complicated queries.
*/