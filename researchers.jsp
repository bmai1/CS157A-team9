<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%
  String pageTitle = "Find researchers | ResearchMatch";
  String error = null;

  // 1. Read what the student typed into the search form.
  //    getParameter returns null when the page first opens (nothing searched yet).
  String name = request.getParameter("name");
  String department = request.getParameter("department");
  String location = request.getParameter("location");
  String areaId = request.getParameter("area");               // drop down: an area_id, or "" for any
  String universityId = request.getParameter("university");   // drop down: a university_id, or "" for any
  boolean phdOnly = "1".equals(request.getParameter("phd"));   // checkbox sends "1" when checked

  if (name == null) name = "";
  if (department == null) department = "";
  if (location == null) location = "";
  if (areaId == null) areaId = "";
  if (universityId == null) universityId = "";
  name = name.trim();
  department = department.trim();
  location = location.trim();

  List<Map<String, Object>> researchers = new ArrayList<>();
  List<Map<String, Object>> areas = new ArrayList<>();          // choices for the Research area drop-down
  List<Map<String, Object>> universities = new ArrayList<>();   // choices for the University drop-down

  try (Connection con = getConnection(application)) {
    // 0. Fill the two drop-downs from the database, so new areas/universities show up automatically.
    Statement listStmt = con.createStatement();
    ResultSet areaRs = listStmt.executeQuery("SELECT area_id, name FROM research_area ORDER BY name");
    while (areaRs.next()) {
      Map<String, Object> a = new HashMap<>();
      a.put("id", String.valueOf(areaRs.getInt("area_id")));
      a.put("name", areaRs.getString("name"));
      areas.add(a);
    }
    ResultSet uniRs = listStmt.executeQuery("SELECT university_id, name FROM university ORDER BY name");
    while (uniRs.next()) {
      Map<String, Object> un = new HashMap<>();
      un.put("id", String.valueOf(uniRs.getInt("university_id")));
      un.put("name", uniRs.getString("name"));
      universities.add(un);
    }

    // 2. Build the query. "WHERE 1=1" is always true, so every filter below
    //    can just add "AND ..." without worrying whether it is the first one.
    StringBuilder sql = new StringBuilder(
        "SELECT r.researcher_id, u.first_name, u.last_name, r.accepting_phd, "
      + "       d.name AS department_name, un.name AS university_name, un.city, un.state "
      + "FROM researcher r "
      + "JOIN users u       ON u.user_id = r.researcher_id "
      + "JOIN department d  ON d.department_id = r.department_id "
      + "JOIN university un ON un.university_id = d.university_id "
      + "WHERE 1=1 ");

    // The values for the ? placeholders, in the same order as the ?s
    List<Object> params = new ArrayList<>();

    if (!name.isEmpty()) {
      sql.append("AND CONCAT(u.first_name, ' ', u.last_name) LIKE ? ");
      params.add("%" + name + "%");          // % means "anything", so this finds partial names
    }
    if (!department.isEmpty()) {
      sql.append("AND d.name LIKE ? ");
      params.add("%" + department + "%");
    }
    if (!location.isEmpty()) {
      sql.append("AND (un.city LIKE ? OR un.state LIKE ? OR un.country LIKE ?) ");
      params.add("%" + location + "%");
      params.add("%" + location + "%");
      params.add("%" + location + "%");
    }
    if (!areaId.isEmpty()) {
      // research areas are many-many, so they live in the junction table researcher_research_area.
      // Keep only researchers whose id appears there together with the chosen area.
      sql.append("AND r.researcher_id IN "
               + "(SELECT rra.researcher_id FROM researcher_research_area rra WHERE rra.area_id = ?) ");
      params.add(Integer.parseInt(areaId));
    }
    if (!universityId.isEmpty()) {
      sql.append("AND un.university_id = ? ");
      params.add(Integer.parseInt(universityId));
    }
    if (phdOnly) {
      sql.append("AND r.accepting_phd = 1 ");
    }
    sql.append("ORDER BY u.last_name");

    // 3. PreparedStatement fills in each ? safely, so typing something like
    //    ' OR 1=1 -- into the search box can't change the SQL (no SQL injection).
    PreparedStatement ps = con.prepareStatement(sql.toString());
    for (int i = 0; i < params.size(); i++) {
      ps.setObject(i + 1, params.get(i));    // the first ? is number 1, not 0
    }
    ResultSet rs = ps.executeQuery();

    while (rs.next()) {
      Map<String, Object> row = new HashMap<>();
      row.put("id", rs.getInt("researcher_id"));
      row.put("name", rs.getString("first_name") + " " + rs.getString("last_name"));
      row.put("department", rs.getString("department_name"));
      row.put("university", rs.getString("university_name"));
      row.put("location", rs.getString("city") + ", " + rs.getString("state"));
      row.put("phd", rs.getInt("accepting_phd") == 1);
      researchers.add(row);
    }
  } catch (Exception e) {
    error = e.getMessage();
  }
%>
<%@ include file="includes/header.jspf" %>

<section class="page">
  <div class="container">
    <h1>Find researchers</h1>
    <p class="sub">Search by name, research area, university, department, or location.</p>

    <div class="search-layout">
      <!-- Search form: sends the filters back to this same page.
           value="..." keeps what you typed in the box after searching. -->
      <form class="filters" action="researchers.jsp" method="get">
        <div class="field">
          <label for="name">Researcher name</label>
          <input type="text" id="name" name="name" value="<%= esc(name) %>" placeholder="e.g. Bennett">
        </div>
        <div class="field">
          <label for="area">Research area</label>
          <select id="area" name="area">
            <option value="">Any area</option>
            <% for (Map<String, Object> a : areas) { %>
              <option value="<%= a.get("id") %>" <%= a.get("id").equals(areaId) ? "selected" : "" %>><%= esc(a.get("name")) %></option>
            <% } %>
          </select>
        </div>
        <div class="field">
          <label for="university">University</label>
          <select id="university" name="university">
            <option value="">Any university</option>
            <% for (Map<String, Object> un : universities) { %>
              <option value="<%= un.get("id") %>" <%= un.get("id").equals(universityId) ? "selected" : "" %>><%= esc(un.get("name")) %></option>
            <% } %>
          </select>
        </div>
        <div class="field">
          <label for="department">Department</label>
          <input type="text" id="department" name="department" value="<%= esc(department) %>" placeholder="e.g. Computer Science">
        </div>
        <div class="field">
          <label for="location">Location</label>
          <input type="text" id="location" name="location" value="<%= esc(location) %>" placeholder="City, state, or country">
        </div>
        <div class="field">
          <label class="check">
            <input type="checkbox" name="phd" value="1" <%= phdOnly ? "checked" : "" %>>
            Only researchers accepting PhD students
          </label>
        </div>
        <button type="submit" class="btn btn-primary">Search</button>
        <a class="reset" href="researchers.jsp">Clear filters</a>
      </form>

      <!-- Results from the database -->
      <div class="results">
        <% if (error != null) { %>
          <p class="empty">Database error: <%= esc(error) %></p>
        <% } else if (researchers.isEmpty()) { %>
          <p class="empty">No researchers match your search. Try removing a filter.</p>
        <% } else { %>
          <p class="result-count"><%= researchers.size() %> researcher<%= researchers.size() == 1 ? "" : "s" %> found</p>

          <% for (Map<String, Object> r : researchers) {
               boolean phd = (Boolean) r.get("phd"); %>
            <div class="result">
              <div class="result-top">
                <span class="result-title"><%= esc(r.get("name")) %></span>
                <span class="badge <%= phd ? "badge-yes" : "" %>">
                  <%= phd ? "Accepting PhD students" : "Not accepting PhD students" %>
                </span>
              </div>
              <p class="result-meta"><%= esc(r.get("department")) %></p>
              <p class="result-meta"><%= esc(r.get("university")) %> &middot; <%= esc(r.get("location")) %></p>
            </div>
          <% } %>
        <% } %>
      </div>
    </div>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>