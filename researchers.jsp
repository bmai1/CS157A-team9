<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%
  String pageTitle = "Find researchers | ResearchMatch";
  String error = null;

  // Each researcher becomes one Map (column name -> value), and all of them go in this list
  List<Map<String, Object>> researchers = new ArrayList<>();

  try (Connection con = getConnection(application)) {
    // I tested this query in workbench first
    String sql =
        "SELECT r.researcher_id, u.first_name, u.last_name, "
      + "       d.name AS department_name, un.name AS university_name, r.accepting_phd "
      + "FROM researcher r "
      + "JOIN users u       ON u.user_id = r.researcher_id "
      + "JOIN department d  ON d.department_id = r.department_id "
      + "JOIN university un ON un.university_id = d.university_id "
      + "ORDER BY u.last_name";

    Statement stmt = con.createStatement();
    ResultSet rs = stmt.executeQuery(sql);

    // Go through the result rows one at a time, like the rows in Workbench
    while (rs.next()) {
      Map<String, Object> row = new HashMap<>();
      row.put("id", rs.getInt("researcher_id"));
      row.put("name", rs.getString("first_name") + " " + rs.getString("last_name"));
      row.put("department", rs.getString("department_name"));
      row.put("university", rs.getString("university_name"));
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
      <!-- Search form: sends the filters back to this same page -->
      <form class="filters" action="researchers.jsp" method="get">
        <div class="field">
          <label for="name">Researcher name</label>
          <input type="text" id="name" name="name" placeholder="e.g. Bennett">
        </div>
        <div class="field">
          <label for="department">Department</label>
          <input type="text" id="department" name="department" placeholder="e.g. Computer Science">
        </div>
        <div class="field">
          <label for="location">Location</label>
          <input type="text" id="location" name="location" placeholder="City, state, or country">
        </div>
        <div class="field">
          <label class="check">
            <input type="checkbox" name="phd" value="1">
            Only researchers accepting PhD students
          </label>
        </div>
        <button type="submit" class="btn btn-primary">Search</button>
      </form>

      <!-- Results from the database -->
      <div class="results">
        <% if (error != null) { %>
          <p class="empty">Database error: <%= esc(error) %></p>
        <% } else { %>
          <p class="result-count"><%= researchers.size() %> researchers found</p>

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
              <p class="result-meta"><%= esc(r.get("university")) %></p>
            </div>
          <% } %>
        <% } %>
      </div>
    </div>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>