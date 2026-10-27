## Installation & Setup

### 1. Clone the Repository

Navigate to Tomcat's `webapps` directory and clone the repository:

```bash
cd tomcat/[version]/libexec/webapps
git clone https://github.com/bmai1/CS157A-team9.git
```

Your project should now appear in the `webapps` directory.

<img width="1071" height="545" alt="Repository cloned into Tomcat webapps directory" src="https://github.com/user-attachments/assets/cfda4411-a64b-4bd6-92ad-0c6950719088" />

### 2. Start MySQL and Tomcat

For macOS, this can be done via Homebrew in the Terminal.

### 3. Configure Database

Execute the latest ResearchMatch.sql in MySQLWorkbench to initialize the database.

Inside the project directory, create a `WEB-INF` folder if it doesn't already exist. Inside `WEB-INF`, create a file named `db.properties`.

Add the following:

```properties
db.url=jdbc:mysql://localhost:3306/ResearchMatch
db.user=YOUR_MYSQL_USER
db.password=YOUR_MYSQL_PASSWORD
```

Replace `YOUR_MYSQL_USER` and `YOUR_MYSQL_PASSWORD` with your MySQL credentials.

### 4. Launch ResearchMatch

ResearchMatch login page:

**http://localhost:8080/CS157A-team9/index.jsp**
