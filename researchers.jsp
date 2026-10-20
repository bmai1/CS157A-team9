<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%
  String pageTitle = "Find researchers | ResearchMatch";
  String error = null;
  int researcherCount = 0;

  // Test the connection: count the researchers in the database
  try (Connection con = getConnection(application)) {
    Statement stmt = con.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM researcher");
    if (rs.next()) {
      researcherCount = rs.getInt(1);
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

      <!-- Results: we will fill this in from the database in the next steps -->
      <div class="results">
                <% if (error != null) { %>
          <p class="empty">Database error: <%= esc(error) %></p>
        <% } else { %>
          <p class="empty">Connected! There are <%= researcherCount %> researchers in the database.</p>
        <% } %>
      </div>
    </div>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>