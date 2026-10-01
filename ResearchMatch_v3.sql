-- =====================================================================
-- ResearchMatch v2: full schema + sample data (CS 157A, Team 9)
-- WARNING: this script DROPS and recreates every ResearchMatch table.
--          Any data currently in those tables will be deleted.
--
-- Changes from v1:
--   * first_name / last_name moved from student and researcher up to users
--   * users.role restricted to 'student', 'researcher', or 'admin'
--   * publication <-> researcher is now many-many via researcher_publication
--     (publication.researcher_id removed)
--   * application: primary key is (student_id, opportunity_id), matching the Applies relationship
--   * fixed line breaks inside two saved_researcher constraint names
--
-- Sample data: all people, emails, labs, and publication titles are fictional.
-- Emails/URLs use example.edu (a reserved domain). password_hash values are dummies.
-- Users 1-10 = students, 11-20 = researchers, 21-22 = admins.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `ResearchMatch` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `ResearchMatch`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `application`;
DROP TABLE IF EXISTS `saved_researcher`;
DROP TABLE IF EXISTS `saved_opportunity`;
DROP TABLE IF EXISTS `publication_research_area`;
DROP TABLE IF EXISTS `opportunity_research_area`;
DROP TABLE IF EXISTS `researcher_research_area`;
DROP TABLE IF EXISTS `researcher_publication`;
DROP TABLE IF EXISTS `publication`;
DROP TABLE IF EXISTS `opportunity`;
DROP TABLE IF EXISTS `research_area`;
DROP TABLE IF EXISTS `researcher`;
DROP TABLE IF EXISTS `lab`;
DROP TABLE IF EXISTS `department`;
DROP TABLE IF EXISTS `university`;
DROP TABLE IF EXISTS `student`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------- TABLES -----------------------------

CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` varchar(20) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email_UNIQUE` (`email`),
  CONSTRAINT `chk_users_role` CHECK (`role` in ('student','researcher','admin'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `student` (
  `student_id` int NOT NULL,
  `major` varchar(150) NOT NULL,
  PRIMARY KEY (`student_id`),
  CONSTRAINT `fk_student_user` FOREIGN KEY (`student_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `university` (
  `university_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(200) NOT NULL,
  `city` varchar(100) NOT NULL,
  `state` varchar(100) NOT NULL,
  `country` varchar(100) NOT NULL,
  `website` varchar(255) NOT NULL,
  PRIMARY KEY (`university_id`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `department` (
  `department_id` int NOT NULL AUTO_INCREMENT,
  `university_id` int NOT NULL,
  `name` varchar(150) NOT NULL,
  `website` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`department_id`),
  KEY `fk_department_university_idx` (`university_id`),
  CONSTRAINT `fk_department_university` FOREIGN KEY (`university_id`) REFERENCES `university` (`university_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `lab` (
  `lab_id` int NOT NULL AUTO_INCREMENT,
  `department_id` int NOT NULL,
  `name` varchar(200) NOT NULL,
  `website` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`lab_id`),
  KEY `fk_lab_department_idx` (`department_id`),
  CONSTRAINT `fk_lab_department` FOREIGN KEY (`department_id`) REFERENCES `department` (`department_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `researcher` (
  `researcher_id` int NOT NULL,
  `department_id` int NOT NULL,
  `lab_id` int DEFAULT NULL,
  `academic_title` varchar(100) DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `biography` mediumtext,
  `accepting_phd` tinyint NOT NULL,
  PRIMARY KEY (`researcher_id`),
  KEY `fk_researcher_department_idx` (`department_id`),
  KEY `fk_researcher_lab_idx` (`lab_id`),
  CONSTRAINT `fk_researcher_department` FOREIGN KEY (`department_id`) REFERENCES `department` (`department_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_researcher_lab` FOREIGN KEY (`lab_id`) REFERENCES `lab` (`lab_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_researcher_user` FOREIGN KEY (`researcher_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `research_area` (
  `area_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  `description` mediumtext,
  PRIMARY KEY (`area_id`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `opportunity` (
  `opportunity_id` int NOT NULL AUTO_INCREMENT,
  `researcher_id` int NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` mediumtext NOT NULL,
  `opportunity_type` varchar(50) NOT NULL,
  `funding_available` tinyint NOT NULL,
  `expected_start_term` varchar(50) DEFAULT NULL,
  `application_deadline` date DEFAULT NULL,
  `status` varchar(30) NOT NULL,
  `application_url` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`opportunity_id`),
  KEY `fk_opportunity_researcher_idx` (`researcher_id`),
  CONSTRAINT `fk_opportunity_researcher` FOREIGN KEY (`researcher_id`) REFERENCES `researcher` (`researcher_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `publication` (
  `publication_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `publication_year` varchar(45) NOT NULL,
  `venue` varchar(200) DEFAULT NULL,
  `publication_url` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`publication_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `researcher_publication` (
  `researcher_id` int NOT NULL,
  `publication_id` int NOT NULL,
  PRIMARY KEY (`researcher_id`,`publication_id`),
  KEY `fk_rp_publication_id_idx` (`publication_id`),
  CONSTRAINT `fk_rp_researcher_id` FOREIGN KEY (`researcher_id`) REFERENCES `researcher` (`researcher_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_rp_publication_id` FOREIGN KEY (`publication_id`) REFERENCES `publication` (`publication_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `researcher_research_area` (
  `researcher_id` int NOT NULL,
  `area_id` int NOT NULL,
  PRIMARY KEY (`researcher_id`,`area_id`),
  KEY `fk_rra_area_id_idx` (`area_id`),
  CONSTRAINT `fk_rra_researcher_id` FOREIGN KEY (`researcher_id`) REFERENCES `researcher` (`researcher_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_rra_area_id` FOREIGN KEY (`area_id`) REFERENCES `research_area` (`area_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `opportunity_research_area` (
  `opportunity_id` int NOT NULL,
  `area_id` int NOT NULL,
  PRIMARY KEY (`opportunity_id`,`area_id`),
  KEY `fk_ora_area_id_idx` (`area_id`),
  CONSTRAINT `fk_ora_opportunity_id` FOREIGN KEY (`opportunity_id`) REFERENCES `opportunity` (`opportunity_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ora_area_id` FOREIGN KEY (`area_id`) REFERENCES `research_area` (`area_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `publication_research_area` (
  `publication_id` int NOT NULL,
  `area_id` int NOT NULL,
  PRIMARY KEY (`publication_id`,`area_id`),
  KEY `fk_pra_area_id_idx` (`area_id`),
  CONSTRAINT `fk_pra_publication_id` FOREIGN KEY (`publication_id`) REFERENCES `publication` (`publication_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pra_area_id` FOREIGN KEY (`area_id`) REFERENCES `research_area` (`area_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `saved_opportunity` (
  `student_id` int NOT NULL,
  `opportunity_id` int NOT NULL,
  `saved_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` mediumtext,
  PRIMARY KEY (`student_id`,`opportunity_id`),
  KEY `fk_saved_opportunity_opportunity_idx` (`opportunity_id`),
  CONSTRAINT `fk_saved_opportunity_opportunity` FOREIGN KEY (`opportunity_id`) REFERENCES `opportunity` (`opportunity_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_saved_opportunity_student` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `saved_researcher` (
  `student_id` int NOT NULL,
  `researcher_id` int NOT NULL,
  `saved_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` mediumtext,
  PRIMARY KEY (`student_id`,`researcher_id`),
  KEY `fk_saved_researcher_researcher_idx` (`researcher_id`),
  CONSTRAINT `fk_saved_researcher_researcher` FOREIGN KEY (`researcher_id`) REFERENCES `researcher` (`researcher_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_saved_researcher_student` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `application` (
  `student_id` int NOT NULL,
  `opportunity_id` int NOT NULL,
  `status` varchar(45) NOT NULL,
  `date_started` date NOT NULL,
  `date_submitted` date DEFAULT NULL,
  `notes` mediumtext,
  PRIMARY KEY (`student_id`,`opportunity_id`),
  KEY `fk_application_opportunity_idx` (`opportunity_id`),
  CONSTRAINT `fk_application_opportunity` FOREIGN KEY (`opportunity_id`) REFERENCES `opportunity` (`opportunity_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_application_student` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------- SAMPLE DATA ---------------------------

START TRANSACTION;

-- users (22 rows)
INSERT INTO `users` (`user_id`, `first_name`, `last_name`, `email`, `password_hash`, `role`, `created_at`) VALUES
  (1, 'Alex', 'Nguyen', 'alex.nguyen@student.example.edu', '$2b$12$DUMMYHASHstudent01xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-01 09:15:00'),
  (2, 'Priya', 'Sharma', 'priya.sharma@student.example.edu', '$2b$12$DUMMYHASHstudent02xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-02 10:15:00'),
  (3, 'Daniel', 'Kim', 'daniel.kim@student.example.edu', '$2b$12$DUMMYHASHstudent03xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-03 11:15:00'),
  (4, 'Maria', 'Lopez', 'maria.lopez@student.example.edu', '$2b$12$DUMMYHASHstudent04xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-04 12:15:00'),
  (5, 'Ethan', 'Tran', 'ethan.tran@student.example.edu', '$2b$12$DUMMYHASHstudent05xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-05 13:15:00'),
  (6, 'Sofia', 'Patel', 'sofia.patel@student.example.edu', '$2b$12$DUMMYHASHstudent06xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-06 14:15:00'),
  (7, 'Jordan', 'Lee', 'jordan.lee@student.example.edu', '$2b$12$DUMMYHASHstudent07xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-07 15:15:00'),
  (8, 'Aisha', 'Rahman', 'aisha.rahman@student.example.edu', '$2b$12$DUMMYHASHstudent08xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-08 16:15:00'),
  (9, 'Kevin', 'Chen', 'kevin.chen@student.example.edu', '$2b$12$DUMMYHASHstudent09xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-09 09:15:00'),
  (10, 'Emily', 'Garcia', 'emily.garcia@student.example.edu', '$2b$12$DUMMYHASHstudent10xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'student', '2026-07-10 10:15:00'),
  (11, 'Laura', 'Bennett', 'laura.bennett@faculty.example.edu', '$2b$12$DUMMYHASHresearcher11xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-01 11:30:00'),
  (12, 'Rajesh', 'Iyer', 'rajesh.iyer@faculty.example.edu', '$2b$12$DUMMYHASHresearcher12xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-02 11:30:00'),
  (13, 'Hannah', 'Weiss', 'hannah.weiss@faculty.example.edu', '$2b$12$DUMMYHASHresearcher13xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-03 11:30:00'),
  (14, 'Marcus', 'Oyelaran', 'marcus.oyelaran@faculty.example.edu', '$2b$12$DUMMYHASHresearcher14xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-04 11:30:00'),
  (15, 'Mei', 'Takahashi', 'mei.takahashi@faculty.example.edu', '$2b$12$DUMMYHASHresearcher15xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-05 11:30:00'),
  (16, 'Carlos', 'Mendoza', 'carlos.mendoza@faculty.example.edu', '$2b$12$DUMMYHASHresearcher16xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-06 11:30:00'),
  (17, 'Sarah', 'Goldberg', 'sarah.goldberg@faculty.example.edu', '$2b$12$DUMMYHASHresearcher17xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-07 11:30:00'),
  (18, 'Tomasz', 'Nowak', 'tomasz.nowak@faculty.example.edu', '$2b$12$DUMMYHASHresearcher18xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-08 11:30:00'),
  (19, 'Nadia', 'Haddad', 'nadia.haddad@faculty.example.edu', '$2b$12$DUMMYHASHresearcher19xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-09 11:30:00'),
  (20, 'Brian', 'Okafor', 'brian.okafor@faculty.example.edu', '$2b$12$DUMMYHASHresearcher20xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'researcher', '2026-06-10 11:30:00'),
  (21, 'Olivia', 'Park', 'olivia.park@admin.example.edu', '$2b$12$DUMMYHASHadmin21xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'admin', '2026-05-01 09:00:00'),
  (22, 'Samuel', 'Reyes', 'samuel.reyes@admin.example.edu', '$2b$12$DUMMYHASHadmin22xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', 'admin', '2026-05-02 09:00:00');

-- student (10 rows)
INSERT INTO `student` (`student_id`, `major`) VALUES
  (1, 'Computer Science'),
  (2, 'Computer Science'),
  (3, 'Software Engineering'),
  (4, 'Data Science'),
  (5, 'Computer Engineering'),
  (6, 'Computer Science'),
  (7, 'Software Engineering'),
  (8, 'Biology'),
  (9, 'Data Science'),
  (10, 'Computer Science');

-- university (10 rows)
INSERT INTO `university` (`university_id`, `name`, `city`, `state`, `country`, `website`) VALUES
  (1, 'San Jose State University', 'San Jose', 'California', 'USA', 'https://www.sjsu.edu'),
  (2, 'Stanford University', 'Stanford', 'California', 'USA', 'https://www.stanford.edu'),
  (3, 'University of California, Berkeley', 'Berkeley', 'California', 'USA', 'https://www.berkeley.edu'),
  (4, 'University of California, Los Angeles', 'Los Angeles', 'California', 'USA', 'https://www.ucla.edu'),
  (5, 'University of California, San Diego', 'La Jolla', 'California', 'USA', 'https://ucsd.edu'),
  (6, 'Santa Clara University', 'Santa Clara', 'California', 'USA', 'https://www.scu.edu'),
  (7, 'University of Washington', 'Seattle', 'Washington', 'USA', 'https://www.washington.edu'),
  (8, 'Carnegie Mellon University', 'Pittsburgh', 'Pennsylvania', 'USA', 'https://www.cmu.edu'),
  (9, 'Massachusetts Institute of Technology', 'Cambridge', 'Massachusetts', 'USA', 'https://www.mit.edu'),
  (10, 'Georgia Institute of Technology', 'Atlanta', 'Georgia', 'USA', 'https://www.gatech.edu');

-- department (10 rows)
INSERT INTO `department` (`department_id`, `university_id`, `name`, `website`) VALUES
  (1, 1, 'Department of Computer Science', 'https://www.sjsu.edu/cs/'),
  (2, 2, 'Department of Computer Science', 'https://cs.stanford.edu'),
  (3, 3, 'Electrical Engineering and Computer Sciences', 'https://eecs.berkeley.edu'),
  (4, 4, 'Computer Science Department', 'https://www.cs.ucla.edu'),
  (5, 5, 'Computer Science and Engineering', 'https://cse.ucsd.edu'),
  (6, 6, 'Department of Computer Science and Engineering', NULL),
  (7, 7, 'Paul G. Allen School of Computer Science & Engineering', 'https://www.cs.washington.edu'),
  (8, 8, 'School of Computer Science', 'https://www.cs.cmu.edu'),
  (9, 9, 'Electrical Engineering and Computer Science', 'https://www.eecs.mit.edu'),
  (10, 10, 'School of Computer Science', 'https://www.cc.gatech.edu');

-- lab (10 rows)
INSERT INTO `lab` (`lab_id`, `department_id`, `name`, `website`) VALUES
  (1, 1, 'Data Systems and Analytics Lab', NULL),
  (2, 2, 'Trustworthy Machine Learning Group', NULL),
  (3, 3, 'Language and Meaning Lab', NULL),
  (4, 4, 'Visual Computing Lab', NULL),
  (5, 5, 'Secure Systems Lab', NULL),
  (6, 6, 'Human-Centered Computing Lab', NULL),
  (7, 7, 'Scalable Distributed Systems Lab', NULL),
  (8, 8, 'Autonomous Robotics Lab', NULL),
  (9, 9, 'Computational Biology Group', NULL),
  (10, 10, 'Hardware Architecture Research Lab', NULL);

-- researcher (10 rows)
INSERT INTO `researcher` (`researcher_id`, `department_id`, `lab_id`, `academic_title`, `contact_email`, `website`, `biography`, `accepting_phd`) VALUES
  (11, 1, 1, 'Associate Professor', 'laura.bennett@faculty.example.edu', 'https://faculty.example.edu/laura-bennett', 'Works on query optimization and data systems for large analytical workloads.', 1),
  (12, 2, 2, 'Assistant Professor', 'rajesh.iyer@faculty.example.edu', 'https://faculty.example.edu/rajesh-iyer', 'Studies robustness and fairness in machine learning models.', 1),
  (13, 3, 3, 'Professor', 'hannah.weiss@faculty.example.edu', 'https://faculty.example.edu/hannah-weiss', 'Researches semantic parsing and multilingual language models.', 0),
  (14, 4, 4, 'Assistant Professor', 'marcus.oyelaran@faculty.example.edu', 'https://faculty.example.edu/marcus-oyelaran', 'Focuses on 3D scene understanding and video analysis.', 1),
  (15, 5, 5, 'Associate Professor', 'mei.takahashi@faculty.example.edu', 'https://faculty.example.edu/mei-takahashi', 'Works on systems security, including memory safety and intrusion detection.', 1),
  (16, 6, NULL, 'Lecturer', 'carlos.mendoza@faculty.example.edu', 'https://faculty.example.edu/carlos-mendoza', 'Teaches and researches accessible user interface design.', 0),
  (17, 7, 7, 'Professor', 'sarah.goldberg@faculty.example.edu', 'https://faculty.example.edu/sarah-goldberg', 'Builds fault-tolerant storage and consensus systems.', 1),
  (18, 8, 8, 'Research Scientist', 'tomasz.nowak@faculty.example.edu', 'https://faculty.example.edu/tomasz-nowak', 'Develops motion planning methods for mobile robots.', 0),
  (19, 9, NULL, 'Assistant Professor', 'nadia.haddad@faculty.example.edu', 'https://faculty.example.edu/nadia-haddad', 'Applies machine learning to genomic and protein sequence data.', 1),
  (20, 10, 10, 'Associate Professor', 'brian.okafor@faculty.example.edu', 'https://faculty.example.edu/brian-okafor', 'Designs energy-efficient processors and memory systems.', 1);

-- research_area (10 rows)
INSERT INTO `research_area` (`area_id`, `name`, `description`) VALUES
  (1, 'Databases', 'Design, storage, querying, and optimization of large-scale data management systems.'),
  (2, 'Machine Learning', 'Algorithms that learn patterns from data to make predictions or decisions.'),
  (3, 'Natural Language Processing', 'Computational methods for understanding and generating human language.'),
  (4, 'Computer Vision', 'Techniques that let computers interpret images and video.'),
  (5, 'Cybersecurity', 'Protecting systems, networks, and data from attacks and unauthorized access.'),
  (6, 'Human-Computer Interaction', 'Studying and designing how people interact with technology.'),
  (7, 'Distributed Systems', 'Systems whose components run on networked computers and coordinate by message passing.'),
  (8, 'Robotics', 'Design and control of robots that sense and act in the physical world.'),
  (9, 'Bioinformatics', 'Computational analysis of biological data such as DNA and protein sequences.'),
  (10, 'Computer Architecture', 'Design of processors, memory hierarchies, and hardware systems.');

-- opportunity (10 rows)
INSERT INTO `opportunity` (`opportunity_id`, `researcher_id`, `title`, `description`, `opportunity_type`, `funding_available`, `expected_start_term`, `application_deadline`, `status`, `application_url`) VALUES
  (1, 11, 'Undergraduate Research Assistant: Query Optimization', 'Help benchmark and improve a query optimizer for analytical SQL workloads.', 'Undergraduate Research', 1, 'Spring 2027', '2026-11-15', 'Open', 'https://apply.example.edu/opportunities/1'),
  (2, 11, 'Summer Data Engineering Internship', 'Build data pipelines and dashboards for an ongoing database research project.', 'Summer Internship', 1, 'Summer 2027', '2027-02-01', 'Open', 'https://apply.example.edu/opportunities/2'),
  (3, 12, 'PhD Position in Robust Machine Learning', 'Fully funded PhD position studying model robustness under distribution shift.', 'PhD Position', 1, 'Fall 2027', '2026-12-01', 'Open', 'https://apply.example.edu/opportunities/3'),
  (4, 13, 'Volunteer Annotator for Multilingual NLP Dataset', 'Assist with labeling and quality-checking sentences in several languages.', 'Volunteer', 0, 'Fall 2026', '2026-09-01', 'Closed', NULL),
  (5, 14, 'Research Assistant: Video Understanding', 'Implement and evaluate models for action recognition in video.', 'Research Assistant', 1, 'Spring 2027', '2026-11-30', 'Open', 'https://apply.example.edu/opportunities/5'),
  (6, 15, 'Undergraduate Security Research Project', 'Explore fuzzing techniques to find memory-safety bugs in open-source software.', 'Undergraduate Research', 0, 'Spring 2027', '2026-12-15', 'Open', NULL),
  (7, 17, 'Distributed Systems Research Assistant', 'Contribute to a fault-tolerant key-value store and run large-scale experiments.', 'Research Assistant', 1, 'Fall 2026', '2026-08-15', 'Filled', 'https://apply.example.edu/opportunities/7'),
  (8, 18, 'Robotics Summer Internship', 'Work on motion planning and simulation for warehouse robots.', 'Summer Internship', 1, 'Summer 2027', '2027-01-31', 'Open', 'https://apply.example.edu/opportunities/8'),
  (9, 19, 'Bioinformatics Undergraduate Researcher', 'Analyze protein sequence data using Python and machine learning tools.', 'Undergraduate Research', 0, 'Spring 2027', NULL, 'Open', NULL),
  (10, 20, 'PhD Position in Energy-Efficient Architecture', 'Funded PhD position on low-power processor and memory design.', 'PhD Position', 1, 'Fall 2027', '2026-12-15', 'Open', 'https://apply.example.edu/opportunities/10');

-- publication (10 rows)
INSERT INTO `publication` (`publication_id`, `title`, `publication_year`, `venue`, `publication_url`) VALUES
  (1, 'Adaptive Join Ordering for Analytical Workloads', '2024', 'SIGMOD', NULL),
  (2, 'Certifying Robustness of Classifiers Under Distribution Shift', '2025', 'NeurIPS', NULL),
  (3, 'Low-Resource Semantic Parsing with Cross-Lingual Transfer', '2023', 'ACL', NULL),
  (4, 'Temporal Scene Graphs for Long-Form Video Understanding', '2025', 'CVPR', NULL),
  (5, 'Detecting Use-After-Free Bugs with Guided Fuzzing', '2024', 'USENIX Security', NULL),
  (6, 'Designing Screen-Reader-Friendly Data Visualizations', '2023', 'CHI', NULL),
  (7, 'Fast Leader Election in Geo-Replicated Storage', '2024', 'OSDI', NULL),
  (8, 'Real-Time Motion Planning in Crowded Warehouses', '2025', 'ICRA', NULL),
  (9, 'Predicting Protein Function from Sequence Embeddings', '2024', 'Bioinformatics', NULL),
  (10, 'Reducing Cache Energy with Adaptive Line Sizing', '2023', 'ISCA', NULL);

-- researcher_publication (14 rows)
INSERT INTO `researcher_publication` (`researcher_id`, `publication_id`) VALUES
  (11, 1),
  (12, 2),
  (13, 3),
  (14, 4),
  (15, 5),
  (16, 6),
  (17, 7),
  (18, 8),
  (19, 9),
  (20, 10),
  (17, 1),
  (19, 2),
  (18, 4),
  (12, 9);

-- researcher_research_area (10 rows)
INSERT INTO `researcher_research_area` (`researcher_id`, `area_id`) VALUES
  (11, 1),
  (12, 2),
  (13, 3),
  (13, 2),
  (14, 4),
  (15, 5),
  (16, 6),
  (17, 7),
  (18, 8),
  (19, 9);

-- opportunity_research_area (10 rows)
INSERT INTO `opportunity_research_area` (`opportunity_id`, `area_id`) VALUES
  (1, 1),
  (2, 1),
  (3, 2),
  (4, 3),
  (5, 4),
  (6, 5),
  (7, 7),
  (8, 8),
  (9, 9),
  (10, 10);

-- publication_research_area (10 rows)
INSERT INTO `publication_research_area` (`publication_id`, `area_id`) VALUES
  (1, 1),
  (2, 2),
  (3, 3),
  (4, 4),
  (5, 5),
  (6, 6),
  (7, 7),
  (8, 8),
  (9, 9),
  (9, 2);

-- saved_opportunity (10 rows)
INSERT INTO `saved_opportunity` (`student_id`, `opportunity_id`, `saved_at`, `notes`) VALUES
  (1, 1, '2026-09-02 14:05:00', 'Matches my database class. Ask about hours per week.'),
  (1, 3, '2026-09-03 09:40:00', NULL),
  (2, 3, '2026-09-05 16:20:00', 'Need two recommendation letters.'),
  (3, 6, '2026-09-08 11:00:00', 'Interested in fuzzing.'),
  (4, 2, '2026-09-10 13:45:00', NULL),
  (5, 10, '2026-09-11 10:10:00', 'Compare with other architecture labs.'),
  (6, 5, '2026-09-12 15:30:00', NULL),
  (7, 8, '2026-09-15 12:00:00', 'Deadline is end of January.'),
  (8, 9, '2026-09-18 17:25:00', 'Good fit for biology + CS.'),
  (9, 1, '2026-09-20 08:50:00', NULL);

-- saved_researcher (10 rows)
INSERT INTO `saved_researcher` (`student_id`, `researcher_id`, `saved_at`, `notes`) VALUES
  (1, 11, '2026-09-01 12:00:00', 'Took her database seminar.'),
  (2, 12, '2026-09-04 10:15:00', 'Research matches my ML interests.'),
  (3, 15, '2026-09-07 14:45:00', NULL),
  (4, 11, '2026-09-09 09:30:00', 'Email about data science projects.'),
  (5, 20, '2026-09-11 16:00:00', NULL),
  (6, 14, '2026-09-13 11:20:00', 'Check recent video papers first.'),
  (7, 18, '2026-09-14 13:10:00', NULL),
  (8, 19, '2026-09-17 15:55:00', 'Works on protein sequences.'),
  (9, 17, '2026-09-21 10:40:00', NULL),
  (10, 16, '2026-09-22 14:30:00', 'Interested in accessibility research.');

-- application (10 rows)
INSERT INTO `application` (`student_id`, `opportunity_id`, `status`, `date_started`, `date_submitted`, `notes`) VALUES
  (1, 1, 'Submitted', '2026-09-05', '2026-09-12', 'Attached transcript and resume.'),
  (2, 3, 'Under Review', '2026-09-06', '2026-09-20', NULL),
  (3, 6, 'Draft', '2026-09-15', NULL, 'Still writing statement of interest.'),
  (4, 2, 'Submitted', '2026-09-11', '2026-09-18', NULL),
  (5, 10, 'Draft', '2026-09-22', NULL, NULL),
  (6, 5, 'Under Review', '2026-09-14', '2026-09-25', 'Interview invitation expected.'),
  (7, 7, 'Rejected', '2026-07-20', '2026-08-01', 'Position filled.'),
  (8, 9, 'Submitted', '2026-09-19', '2026-09-27', NULL),
  (9, 1, 'Accepted', '2026-09-02', '2026-09-08', 'Starts in Spring 2027.'),
  (10, 4, 'Rejected', '2026-08-20', '2026-08-30', NULL);

COMMIT;
