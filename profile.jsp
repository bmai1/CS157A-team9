<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%!
  // An empty box is saved as NULL instead of an empty string
  String blankToNull(String s) {
    if (s == null || s.trim().isEmpty()) return null;
    return s.trim();
  }
%>
<%
  // Only logged-in users can see this page
  if (session.getAttribute("userId") == null) {
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
  }

  request.setCharacterEncoding("UTF-8");           // read form text as UTF-8 
  String pageTitle = "My profile | ResearchMatch";
  String error = null;
  String message = "1".equals(request.getParameter("saved")) ? "Your changes were saved." : null;

  int userId = (Integer) session.getAttribute("userId");                 // who is logged in
  boolean isResearcher = "researcher".equals(session.getAttribute("userRole"));
  boolean isStudent = "student".equals(session.getAttribute("userRole"));

  Map<String, Object> account = null;                // the users row
  Map<String, Object> details = null;                // the researcher row (null if not filled in yet)
  List<Map<String, Object>> departments = new ArrayList<>();
  List<Map<String, Object>> labs = new ArrayList<>();
  List<Map<String, Object>> allAreas = new ArrayList<>();          // every research area, for the checkboxes
  Set<String> myAreas = new HashSet<>();
  List<Map<String, Object>> myOpps = new ArrayList<>();            // this researcher's opportunities
  String[] oppTypes = {"Undergraduate Research", "Research Assistant", "PhD Position", "Summer Internship", "Volunteer"};
  String[] oppStatuses = {"Open", "Closed", "Filled"};
  String major = null;                                             // the student row's major (null if not filled in yet)

  try (Connection con = getConnection(application)) {
    // 1. Save a form, if one was submitted. Each form has a hidden "form" field
    //    saying which one it is.
    if ("POST".equalsIgnoreCase(request.getMethod())) {
      String form = request.getParameter("form");

      if ("account".equals(form)) {
        // 1a. Name: UPDATE one row of users, the logged-in user's
        String firstName = blankToNull(request.getParameter("first_name"));
        String lastName = blankToNull(request.getParameter("last_name"));
        if (firstName == null || lastName == null) {
          error = "Please enter your first and last name.";
        } else {
          PreparedStatement upd = con.prepareStatement(
              "UPDATE users SET first_name = ?, last_name = ? WHERE user_id = ?");
          upd.setString(1, firstName);
          upd.setString(2, lastName);
          upd.setInt(3, userId);
          upd.executeUpdate();                        // UPDATE returns no rows, so executeUpdate

          session.setAttribute("userName", firstName + " " + lastName);   // the header shows the new name
          session.setAttribute("userFirstName", firstName);
          response.sendRedirect(request.getContextPath() + "/profile.jsp?saved=1");
          return;
        }
      } else if ("researcher".equals(form) && isResearcher) {
        // 1b. Researcher details: INSERT the first time, UPDATE after that
        int departmentId = -1;
        try {
          departmentId = Integer.parseInt(request.getParameter("department_id"));
        } catch (NumberFormatException e) {
          
        }
        Integer labId = null;                          // null means "no lab"
        String labParam = request.getParameter("lab_id");
        if (labParam != null && !labParam.isEmpty()) {
          labId = Integer.parseInt(labParam);
        }
        String title = blankToNull(request.getParameter("academic_title"));
        String email = blankToNull(request.getParameter("contact_email"));
        String website = blankToNull(request.getParameter("website"));
        String bio = blankToNull(request.getParameter("biography"));
        boolean phd = "1".equals(request.getParameter("accepting_phd"));

        if (departmentId == -1) {
          error = "Please choose your department.";
        } else if (labId != null) {
          // The lab has to be in the department they chose
          PreparedStatement labCheck = con.prepareStatement(
              "SELECT lab_id FROM lab WHERE lab_id = ? AND department_id = ?");
          labCheck.setInt(1, labId);
          labCheck.setInt(2, departmentId);
          if (!labCheck.executeQuery().next()) {
            error = "That lab is not part of the department you chose.";
          }
        }

        if (error == null) {
          // Is there already a researcher row for this user?
          PreparedStatement exists = con.prepareStatement(
              "SELECT researcher_id FROM researcher WHERE researcher_id = ?");
          exists.setInt(1, userId);
          boolean hasRow = exists.executeQuery().next();

          // Both statements use the same 8 values in the same order,
          // so the setX calls below work for either one.
          PreparedStatement save;
          if (hasRow) {
            save = con.prepareStatement(
                "UPDATE researcher "
              + "SET department_id = ?, lab_id = ?, academic_title = ?, contact_email = ?, "
              + "    website = ?, biography = ?, accepting_phd = ? "
              + "WHERE researcher_id = ?");
          } else {
            save = con.prepareStatement(
                "INSERT INTO researcher (department_id, lab_id, academic_title, contact_email, "
              + "                        website, biography, accepting_phd, researcher_id) "
              + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
          }
          save.setInt(1, departmentId);
          if (labId == null) {
            save.setNull(2, Types.INTEGER);            // SQL NULL: not part of a lab
          } else {
            save.setInt(2, labId);
          }
          save.setString(3, title);                    // setString with null stores NULL
          save.setString(4, email);
          save.setString(5, website);
          save.setString(6, bio);
          save.setInt(7, phd ? 1 : 0);                 
          save.setInt(8, userId);                      // researcher_id is the same as user_id
          save.executeUpdate();

          response.sendRedirect(request.getContextPath() + "/profile.jsp?saved=1");
          return;
        }
      }

      // 1c. Research areas. Studies is many-many, so the areas are rows in the
      //     junction table researcher_research_area. To save the checkboxes we
      //     delete this researcher's old rows, then insert one row per ticked box.
      if ("areas".equals(form) && isResearcher) {
        String[] chosen = request.getParameterValues("area_id");     // null if no box is ticked

        PreparedStatement del = con.prepareStatement(
            "DELETE FROM researcher_research_area WHERE researcher_id = ?");
        del.setInt(1, userId);
        del.executeUpdate();                         // removes only this researcher's rows

        if (chosen != null) {
          // Prepared once, run once per ticked box with a different area_id
          PreparedStatement ins = con.prepareStatement(
              "INSERT INTO researcher_research_area (researcher_id, area_id) VALUES (?, ?)");
          for (String areaId : chosen) {
            ins.setInt(1, userId);
            ins.setInt(2, Integer.parseInt(areaId));
            ins.executeUpdate();
          }
        }

        response.sendRedirect(request.getContextPath() + "/profile.jsp?saved=1");
        return;
      }

      // 1d. Post a new opportunity. Offers is one-many, so the new row just stores
      //     this researcher's id in its researcher_id column.
      if ("newOpportunity".equals(form) && isResearcher) {
        String oTitle = blankToNull(request.getParameter("title"));
        String oDesc = blankToNull(request.getParameter("description"));
        String oType = blankToNull(request.getParameter("opportunity_type"));
        boolean oFunded = "1".equals(request.getParameter("funding_available"));
        String oStart = blankToNull(request.getParameter("expected_start_term"));
        String oDeadline = blankToNull(request.getParameter("application_deadline"));   // "2027-01-15" or null
        String oUrl = blankToNull(request.getParameter("application_url"));

        java.sql.Date deadline = null;                 // stays null if there is no deadline
        if (oDeadline != null) {
          try {
            deadline = java.sql.Date.valueOf(oDeadline); 
          } catch (IllegalArgumentException e) {
            error = "Please enter the deadline as a date.";
          }
        }

        if (oTitle == null || oDesc == null || oType == null) {
          error = "Please fill in the title, description, and type.";
        } else if (error == null) {
          PreparedStatement insOpp = con.prepareStatement(
              "INSERT INTO opportunity (researcher_id, title, description, opportunity_type, funding_available, "
            + "                         expected_start_term, application_deadline, status, application_url) "
            + "VALUES (?, ?, ?, ?, ?, ?, ?, 'Open', ?)");
          insOpp.setInt(1, userId);
          insOpp.setString(2, oTitle);
          insOpp.setString(3, oDesc);
          insOpp.setString(4, oType);
          insOpp.setInt(5, oFunded ? 1 : 0);
          insOpp.setString(6, oStart);
          if (deadline == null) {
            insOpp.setNull(7, Types.DATE);             // SQL NULL: no deadline
          } else {
            insOpp.setDate(7, deadline);
          }
          insOpp.setString(8, oUrl);
          insOpp.executeUpdate();                    // opportunity_id is filled in by AUTO_INCREMENT

          response.sendRedirect(request.getContextPath() + "/profile.jsp?saved=1");
          return;
        }
      }

      //Change an opportunity's status (Open / Closed / Filled).
      //"AND researcher_id = ?" makes sure researchers can only change their own.
      if ("oppStatus".equals(form) && isResearcher) {
        String newStatus = request.getParameter("status");
        if (Arrays.asList(oppStatuses).contains(newStatus)) {
          PreparedStatement updOpp = con.prepareStatement(
              "UPDATE opportunity SET status = ? WHERE opportunity_id = ? AND researcher_id = ?");
          updOpp.setString(1, newStatus);
          updOpp.setInt(2, Integer.parseInt(request.getParameter("opportunity_id")));
          updOpp.setInt(3, userId);
          updOpp.executeUpdate();
        }
        response.sendRedirect(request.getContextPath() + "/profile.jsp?saved=1");
        return;
      }

      // Delete an opportunity, again only if it belongs to this researcher.
      if ("deleteOpp".equals(form) && isResearcher) {
        PreparedStatement delOpp = con.prepareStatement(
            "DELETE FROM opportunity WHERE opportunity_id = ? AND researcher_id = ?");
        delOpp.setInt(1, Integer.parseInt(request.getParameter("opportunity_id")));
        delOpp.setInt(2, userId);
        delOpp.executeUpdate();
        response.sendRedirect(request.getContextPath() + "/profile.jsp?saved=1");
        return;
      }

      // 1g. Student details: INSERT the first time, UPDATE after that.
      //     A student is a user (ISA), so student_id is the same as user_id.
      if ("student".equals(form) && isStudent) {
        String newMajor = blankToNull(request.getParameter("major"));
        if (newMajor == null) {
          error = "Please enter your major.";
        } else {
          PreparedStatement stuExists = con.prepareStatement(
              "SELECT student_id FROM student WHERE student_id = ?");
          stuExists.setInt(1, userId);
          boolean hasStudentRow = stuExists.executeQuery().next();

          // Same 2 values in the same order for both statements
          PreparedStatement saveStu;
          if (hasStudentRow) {
            saveStu = con.prepareStatement("UPDATE student SET major = ? WHERE student_id = ?");
          } else {
            saveStu = con.prepareStatement("INSERT INTO student (major, student_id) VALUES (?, ?)");
          }
          saveStu.setString(1, newMajor);
          saveStu.setInt(2, userId);
          saveStu.executeUpdate();

          response.sendRedirect(request.getContextPath() + "/profile.jsp?saved=1");
          return;
        }
      }
    }

    // 2. Load the account (every user has one row in users)
    PreparedStatement accPs = con.prepareStatement(
        "SELECT first_name, last_name, email, role FROM users WHERE user_id = ?");
    accPs.setInt(1, userId);
    ResultSet accRs = accPs.executeQuery();
    if (accRs.next()) {
      account = new HashMap<>();
      account.put("first", accRs.getString("first_name"));
      account.put("last", accRs.getString("last_name"));
      account.put("email", accRs.getString("email"));
      account.put("role", accRs.getString("role"));
    }

    if (isResearcher) {
      // 3. Load the researcher row, if it exists yet
      PreparedStatement resPs = con.prepareStatement(
          "SELECT department_id, lab_id, academic_title, contact_email, website, biography, accepting_phd "
        + "FROM researcher "
        + "WHERE researcher_id = ?");
      resPs.setInt(1, userId);
      ResultSet resRs = resPs.executeQuery();
      if (resRs.next()) {
        details = new HashMap<>();
        details.put("department", String.valueOf(resRs.getInt("department_id")));
        Object lab = resRs.getObject("lab_id");                        // null when there is no lab
        details.put("lab", lab == null ? "" : lab.toString());
        details.put("title", resRs.getString("academic_title"));
        details.put("email", resRs.getString("contact_email"));
        details.put("website", resRs.getString("website"));
        details.put("bio", resRs.getString("biography"));
        details.put("phd", resRs.getInt("accepting_phd") == 1);
      }

      // 4. Choices for the drop-downs, with the university so names are clear
      Statement listStmt = con.createStatement();
      ResultSet deptRs = listStmt.executeQuery(
          "SELECT d.department_id, d.name, un.name AS university_name "
        + "FROM department d "
        + "JOIN university un ON un.university_id = d.university_id "
        + "ORDER BY un.name, d.name");
      while (deptRs.next()) {
        Map<String, Object> d = new HashMap<>();
        d.put("id", String.valueOf(deptRs.getInt("department_id")));
        d.put("name", deptRs.getString("name") + " (" + deptRs.getString("university_name") + ")");
        departments.add(d);
      }
      ResultSet labRs = listStmt.executeQuery(
          "SELECT l.lab_id, l.name, un.name AS university_name "
        + "FROM lab l "
        + "JOIN department d ON d.department_id = l.department_id "
        + "JOIN university un ON un.university_id = d.university_id "
        + "ORDER BY un.name, l.name");
      while (labRs.next()) {
        Map<String, Object> l = new HashMap<>();
        l.put("id", String.valueOf(labRs.getInt("lab_id")));
        l.put("name", labRs.getString("name") + " (" + labRs.getString("university_name") + ")");
        labs.add(l);
      }

      // 5. Every research area (for the checkboxes) and the ones this researcher has
      ResultSet allAreaRs = listStmt.executeQuery("SELECT area_id, name FROM research_area ORDER BY name");
      while (allAreaRs.next()) {
        Map<String, Object> a = new HashMap<>();
        a.put("id", String.valueOf(allAreaRs.getInt("area_id")));
        a.put("name", allAreaRs.getString("name"));
        allAreas.add(a);
      }
      PreparedStatement myAreaPs = con.prepareStatement(
          "SELECT area_id FROM researcher_research_area WHERE researcher_id = ?");
      myAreaPs.setInt(1, userId);
      ResultSet myAreaRs = myAreaPs.executeQuery();
      while (myAreaRs.next()) {
        myAreas.add(String.valueOf(myAreaRs.getInt("area_id")));
      }

      // 6. This researcher's opportunities, every status, newest first
      PreparedStatement myOppPs = con.prepareStatement(
          "SELECT opportunity_id, title, opportunity_type, application_deadline, status "
        + "FROM opportunity "
        + "WHERE researcher_id = ? "
        + "ORDER BY opportunity_id DESC");
      myOppPs.setInt(1, userId);
      ResultSet myOppRs = myOppPs.executeQuery();
      while (myOppRs.next()) {
        Map<String, Object> o = new HashMap<>();
        o.put("id", myOppRs.getInt("opportunity_id"));
        o.put("title", myOppRs.getString("title"));
        o.put("type", myOppRs.getString("opportunity_type"));
        o.put("deadline", myOppRs.getString("application_deadline"));   // can be NULL
        o.put("status", myOppRs.getString("status"));
        myOpps.add(o);
      }
    }

    if (isStudent) {
      // 7. Load the student row, if it exists yet
      PreparedStatement stuPs = con.prepareStatement("SELECT major FROM student WHERE student_id = ?");
      stuPs.setInt(1, userId);
      ResultSet stuRs = stuPs.executeQuery();
      if (stuRs.next()) {
        major = stuRs.getString("major");
      }
    }
  } catch (Exception e) {
    error = e.getMessage();
  }

  // If saving the researcher form failed, show what they typed instead of the old
  // saved values, so they don't have to fill everything in again.
  boolean isNew = (details == null);
  if (error != null && "researcher".equals(request.getParameter("form"))) {
    details = new HashMap<>();
    details.put("department", request.getParameter("department_id"));
    details.put("lab", request.getParameter("lab_id"));
    details.put("title", request.getParameter("academic_title"));
    details.put("email", request.getParameter("contact_email"));
    details.put("website", request.getParameter("website"));
    details.put("bio", request.getParameter("biography"));
    details.put("phd", "1".equals(request.getParameter("accepting_phd")));
  }

  // What to show in the researcher form: the saved values, or empty for a new researcher
  String selDept = details == null ? "" : String.valueOf(details.get("department"));
  String selLab = details == null ? "" : String.valueOf(details.get("lab"));
  boolean phdChecked = details != null && (Boolean) details.get("phd");
%>
<%@ include file="includes/header.jspf" %>

<section class="page">
  <div class="container narrow">
    <h1>My profile</h1>

    <% if (message != null) { %>
      <p class="notice notice-ok"><%= esc(message) %></p>
    <% } %>
    <% if (error != null) { %>
      <p class="notice notice-error" role="alert"><%= esc(error) %></p>
    <% } %>

    <% if (account != null) { %>
      <!-- Account: name and email, for every user -->
      <div class="card">
        <h2>Account</h2>
        <form action="profile.jsp" method="post">
          <input type="hidden" name="form" value="account">
          <div class="field">
            <label for="first_name">First name</label>
            <input type="text" id="first_name" name="first_name" value="<%= esc(account.get("first")) %>" required>
          </div>
          <div class="field">
            <label for="last_name">Last name</label>
            <input type="text" id="last_name" name="last_name" value="<%= esc(account.get("last")) %>" required>
          </div>
          <div class="field">
            <label>Email</label>
            <p><%= esc(account.get("email")) %> &middot; <%= esc(account.get("role")) %> account</p>
          </div>
          <button type="submit" class="btn btn-primary">Save name</button>
        </form>
      </div>
    <% } %>

    <% if (isResearcher) { %>
      <!-- Researcher details: what students see on the public profile -->
      <div class="card">
        <h2>Researcher details</h2>
        <% if (isNew) { %>
          <p class="hint">Fill this in so students can find you in Researcher search.</p>
        <% } else { %>
          <p class="hint"><a href="researcher.jsp?id=<%= userId %>">View my public profile &rarr;</a></p>
        <% } %>

        <form action="profile.jsp" method="post">
          <input type="hidden" name="form" value="researcher">
          <div class="field">
            <label for="department_id">Department</label>
            <select id="department_id" name="department_id" required>
              <option value="">Choose your department</option>
              <% for (Map<String, Object> d : departments) { %>
                <option value="<%= d.get("id") %>" <%= d.get("id").equals(selDept) ? "selected" : "" %>><%= esc(d.get("name")) %></option>
              <% } %>
            </select>
          </div>
          <div class="field">
            <label for="lab_id">Research lab</label>
            <select id="lab_id" name="lab_id">
              <option value="">Not part of a lab</option>
              <% for (Map<String, Object> l : labs) { %>
                <option value="<%= l.get("id") %>" <%= l.get("id").equals(selLab) ? "selected" : "" %>><%= esc(l.get("name")) %></option>
              <% } %>
            </select>
          </div>
          <div class="field">
            <label for="academic_title">Academic title</label>
            <input type="text" id="academic_title" name="academic_title" value="<%= details == null ? "" : esc(details.get("title")) %>" placeholder="e.g. Associate Professor">
          </div>
          <div class="field">
            <label for="contact_email">Contact email</label>
            <input type="email" id="contact_email" name="contact_email" value="<%= details == null ? "" : esc(details.get("email")) %>">
          </div>
          <div class="field">
            <label for="website">Website</label>
            <input type="url" id="website" name="website" value="<%= details == null ? "" : esc(details.get("website")) %>" placeholder="https://">
          </div>
          <div class="field">
            <label for="biography">Biography</label>
            <textarea id="biography" name="biography" rows="5"><%= details == null ? "" : esc(details.get("bio")) %></textarea>
          </div>
          <div class="field">
            <label class="check">
              <input type="checkbox" name="accepting_phd" value="1" <%= phdChecked ? "checked" : "" %>>
              I am accepting PhD students
            </label>
          </div>
          <button type="submit" class="btn btn-primary">Save details</button>
        </form>
      </div>
      
      <!-- Research areas: one checkbox per area -->
      <div class="card">
        <h2>Research areas</h2>
        <% if (isNew) { %>
          <p class="hint">Save your researcher details first, then choose your research areas.</p>
        <% } else { %>
          <p class="hint">Tick every area you work in. Students can filter by these when they search.</p>
          <form action="profile.jsp" method="post">
            <input type="hidden" name="form" value="areas">
            <div class="checkbox-grid">
              <% for (Map<String, Object> a : allAreas) { %>
                <label class="check">
                  <input type="checkbox" name="area_id" value="<%= a.get("id") %>" <%= myAreas.contains(a.get("id")) ? "checked" : "" %>>
                  <%= esc(a.get("name")) %>
                </label>
              <% } %>
            </div>
            <button type="submit" class="btn btn-primary">Save research areas</button>
          </form>
        <% } %>
      </div>
      
      <!-- My opportunities: the list, and a form to post a new one -->
      <% if (!isNew) {
           // If posting failed, keep what they typed in the new-opportunity form
           boolean keep = error != null && "newOpportunity".equals(request.getParameter("form")); %>
        <div class="card">
          <h2>My opportunities</h2>
          <% if (myOpps.isEmpty()) { %>
            <p class="hint">You haven't posted any opportunities yet.</p>
          <% } else { %>
            <ul class="plain-list">
              <% for (Map<String, Object> o : myOpps) { %>
                                <li class="opp-row">
                  <div>
                    <a class="item-title" href="opportunity.jsp?id=<%= o.get("id") %>"><%= esc(o.get("title")) %></a>
                    <p class="item-meta">
                      <%= esc(o.get("type")) %><%= o.get("deadline") == null ? "" : " &middot; Apply by " + esc(o.get("deadline")) %>
                    </p>
                  </div>
                  <div class="opp-actions">
                    <%-- Change status: one small form per opportunity --%>
                    <form action="profile.jsp" method="post">
                      <input type="hidden" name="form" value="oppStatus">
                      <input type="hidden" name="opportunity_id" value="<%= o.get("id") %>">
                      <select name="status" aria-label="Status">
                        <% for (String st : oppStatuses) { %>
                          <option value="<%= st %>" <%= st.equals(o.get("status")) ? "selected" : "" %>><%= st %></option>
                        <% } %>
                      </select>
                      <button type="submit" class="btn btn-secondary btn-small">Update</button>
                    </form>
                    <form action="profile.jsp" method="post">
                      <input type="hidden" name="form" value="deleteOpp">
                      <input type="hidden" name="opportunity_id" value="<%= o.get("id") %>">
                      <button type="submit" class="btn-link-danger">Delete</button>
                    </form>
                  </div>       
                </li>
              <% } %>
            </ul>
          <% } %>

          <h2 class="card-subhead">Post a new opportunity</h2>
          <form action="profile.jsp" method="post">
            <input type="hidden" name="form" value="newOpportunity">
            <div class="field">
              <label for="title">Title</label>
              <input type="text" id="title" name="title" value="<%= keep ? esc(request.getParameter("title")) : "" %>" required>
            </div>
            <div class="field">
              <label for="description">Description</label>
              <textarea id="description" name="description" rows="4" required><%= keep ? esc(request.getParameter("description")) : "" %></textarea>
            </div>
            <div class="field">
              <label for="opportunity_type">Type</label>
              <select id="opportunity_type" name="opportunity_type" required>
                <option value="">Choose a type</option>
                <% for (String t : oppTypes) { %>
                  <option value="<%= t %>" <%= keep && t.equals(request.getParameter("opportunity_type")) ? "selected" : "" %>><%= t %></option>
                <% } %>
              </select>
            </div>
            <div class="field">
              <label for="expected_start_term">Expected start</label>
              <input type="text" id="expected_start_term" name="expected_start_term" value="<%= keep ? esc(request.getParameter("expected_start_term")) : "" %>" placeholder="e.g. Fall 2027">
            </div>
            <div class="field">
              <label for="application_deadline">Application deadline</label>
              <input type="date" id="application_deadline" name="application_deadline" value="<%= keep ? esc(request.getParameter("application_deadline")) : "" %>">
            </div>
            <div class="field">
              <label for="application_url">Application link</label>
              <input type="url" id="application_url" name="application_url" value="<%= keep ? esc(request.getParameter("application_url")) : "" %>" placeholder="https://">
            </div>
            <div class="field">
              <label class="check">
                <input type="checkbox" name="funding_available" value="1" <%= keep && "1".equals(request.getParameter("funding_available")) ? "checked" : "" %>>
                Funding is available
              </label>
            </div>
            <button type="submit" class="btn btn-primary">Post opportunity</button>
          </form>
        </div>
      <% } %>
    <% } %>
    
    <% if (isStudent) { %>
      <!-- Student details -->
      <div class="card">
        <h2>Student details</h2>
        <% if (major == null) { %>
          <p class="hint">Add your major to finish setting up your student profile.</p>
        <% } %>
        <form action="profile.jsp" method="post">
          <input type="hidden" name="form" value="student">
          <div class="field">
            <label for="major">Major</label>
            <input type="text" id="major" name="major" value="<%= major == null ? "" : esc(major) %>" placeholder="e.g. Computer Science" required>
          </div>
          <button type="submit" class="btn btn-primary">Save major</button>
        </form>
      </div>
    <% } %>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
