<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%
  String pageTitle = "Find universities | ResearchMatch";
  String error = null;

  // 1. Read what the student typed into the search form (null when the page first opens).
  String name = request.getParameter("name");
  String location = request.getParameter("location");
  String department = request.getParameter("department");
  String areaId = request.getParameter("area");               // drop down: an area_id, or "" for any

  if (name == null) name = "";
  if (location == null) location = "";
  if (department == null) department = "";
  if (areaId == null) areaId = "";
  name = name.trim();
  location = location.trim();
  department = department.trim();

  List<Map<String, Object>> universities = new ArrayList<>();
  List<Map<String, Object>> areas = new ArrayList<>();             // choices for the Research area drop-down
  Map<Integer, Integer> researcherCount = new HashMap<>();         // university_id -> number of researchers
  Map<Integer, List<String>> areasByUniversity = new HashMap<>();  // university_id -> research areas studied there

  try (Connection con = getConnection(application)) {
    // 0. Fill the Research area drop-down from the database.
    Statement listStmt = con.createStatement();
    ResultSet areaRs = listStmt.executeQuery("SELECT area_id, name FROM research_area ORDER BY name");
    while (areaRs.next()) {
      Map<String, Object> a = new HashMap<>();
      a.put("id", String.valueOf(areaRs.getInt("area_id")));
      a.put("name", areaRs.getString("name"));
      areas.add(a);
    }

    // 2. Build the search query: "WHERE 1=1" is always
    //    true, so each filter below just adds "AND ...".
    StringBuilder sql = new StringBuilder(
        "SELECT un.university_id, un.name, un.city, un.state, un.country "
      + "FROM university un "
      + "WHERE 1=1 ");
    List<Object> params = new ArrayList<>();       // values for the ?s, in order

    if (!name.isEmpty()) {
      sql.append("AND un.name LIKE ? ");
      params.add("%" + name + "%");
    }
    if (!location.isEmpty()) {
      sql.append("AND (un.city LIKE ? OR un.state LIKE ? OR un.country LIKE ?) ");
      params.add("%" + location + "%");
      params.add("%" + location + "%");
      params.add("%" + location + "%");
    }
    if (!department.isEmpty()) {
      // Has is one-many (a university has many departments), so keep a university
      // if its id is among the universities that have a department with a matching name.
      sql.append("AND un.university_id IN "
               + "(SELECT d.university_id FROM department d WHERE d.name LIKE ?) ");
      params.add("%" + department + "%");
    }
    if (!areaId.isEmpty()) {
      // A university "does" a research area if one of its researchers studies it:
      // university -> department -> researcher -> researcher_research_area.
      sql.append("AND un.university_id IN "
               + "(SELECT d.university_id "
               + " FROM department d "
               + " JOIN researcher r ON r.department_id = d.department_id "
               + " JOIN researcher_research_area rra ON rra.researcher_id = r.researcher_id "
               + " WHERE rra.area_id = ?) ");
      params.add(Integer.parseInt(areaId));
    }
    sql.append("ORDER BY un.name");

    // 3. PreparedStatement fills in each ? safely (no SQL injection).
    PreparedStatement ps = con.prepareStatement(sql.toString());
    for (int i = 0; i < params.size(); i++) {
      ps.setObject(i + 1, params.get(i));          // the first ? is number 1
    }
    ResultSet rs = ps.executeQuery();
    while (rs.next()) {
      Map<String, Object> row = new HashMap<>();
      row.put("id", rs.getInt("university_id"));
      row.put("name", rs.getString("name"));
      row.put("location", rs.getString("city") + ", " + rs.getString("state") + ", " + rs.getString("country"));
      universities.add(row);
    }

    // 4. How many researchers each university has: GROUP BY + COUNT(*).
    //    Universities with no researchers don't appear here; the page shows 0 for them.
    ResultSet countRs = listStmt.executeQuery(
        "SELECT d.university_id, COUNT(*) AS researcher_count "
      + "FROM researcher r "
      + "JOIN department d ON d.department_id = r.department_id "
      + "GROUP BY d.university_id");
    while (countRs.next()) {
      researcherCount.put(countRs.getInt("university_id"), countRs.getInt("researcher_count"));
    }

    // 5. The research areas studied at each university. DISTINCT removes repeats when
    //    two researchers at the same university study the same area.
    ResultSet uniAreaRs = listStmt.executeQuery(
        "SELECT DISTINCT d.university_id, ra.name "
      + "FROM department d "
      + "JOIN researcher r ON r.department_id = d.department_id "
      + "JOIN researcher_research_area rra ON rra.researcher_id = r.researcher_id "
      + "JOIN research_area ra ON ra.area_id = rra.area_id "
      + "ORDER BY ra.name");
    while (uniAreaRs.next()) {
      int universityId = uniAreaRs.getInt("university_id");
      if (!areasByUniversity.containsKey(universityId)) {
        areasByUniversity.put(universityId, new ArrayList<>());  // first area for this university
      }
      areasByUniversity.get(universityId).add(uniAreaRs.getString("name"));
    }
  } catch (Exception e) {
    error = e.getMessage();
  }
%>
<%@ include file="includes/header.jspf" %>

<section class="page">
  <div class="container">
    <h1>Find universities</h1>
    <p class="sub">Search by name, location, department, or research area.</p>

    <div class="search-layout">
      <!-- Search form: sends the filters back to this same page -->
      <form class="filters" action="universities.jsp" method="get">
        <div class="field">
          <label for="name">University name</label>
          <input type="text" id="name" name="name" value="<%= esc(name) %>" placeholder="e.g. Stanford">
        </div>
        <div class="field">
          <label for="location">Location</label>
          <input type="text" id="location" name="location" value="<%= esc(location) %>" placeholder="City, state, or country">
        </div>
        <div class="field">
          <label for="department">Department</label>
          <input type="text" id="department" name="department" value="<%= esc(department) %>" placeholder="e.g. Computer Science">
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
        <button type="submit" class="btn btn-primary">Search</button>
        <a class="reset" href="universities.jsp">Clear filters</a>
      </form>

      <!-- Results from the database -->
      <div class="results">
        <% if (error != null) { %>
          <p class="empty">Database error: <%= esc(error) %></p>
        <% } else if (universities.isEmpty()) { %>
          <p class="empty">No universities match your search. Try removing a filter.</p>
        <% } else { %>
          <p class="result-count"><%= universities.size() %> universit<%= universities.size() == 1 ? "y" : "ies" %> found</p>

          <% for (Map<String, Object> un : universities) {
               Integer count = researcherCount.get((Integer) un.get("id"));
               if (count == null) count = 0;                              // no researchers yet
               List<String> uAreas = areasByUniversity.get((Integer) un.get("id")); %>
            <a class="result" href="university.jsp?id=<%= un.get("id") %>">
              <div class="result-top">
                <span class="result-title"><%= esc(un.get("name")) %></span>
                <span class="badge"><%= count %> researcher<%= count == 1 ? "" : "s" %></span>
              </div>
              <p class="result-meta"><%= esc(un.get("location")) %></p>

              <%-- Research areas as small tags. Some universities have none, so check for null. --%>
              <% if (uAreas != null) { %>
                <ul class="chips">
                  <% for (String areaName : uAreas) { %>
                    <li><%= esc(areaName) %></li>
                  <% } %>
                </ul>
              <% } %>
            </a>
          <% } %>
        <% } %>
      </div>
    </div>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
