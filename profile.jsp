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

  Map<String, Object> account = null;                // the users row
  Map<String, Object> details = null;                // the researcher row (null if not filled in yet)
  List<Map<String, Object>> departments = new ArrayList<>();
  List<Map<String, Object>> labs = new ArrayList<>();
  List<Map<String, Object>> allAreas = new ArrayList<>();          // every research area, for the checkboxes
  Set<String> myAreas = new HashSet<>();                           // area_ids this researcher has ticked

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
          // nothing chosen: stays -1
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
          save.setInt(7, phd ? 1 : 0);                 // MySQL stores true/false as 1/0
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
    <% } %>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
