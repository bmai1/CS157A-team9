<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String pageTitle = "Log in | ResearchMatch"; %>
<%@ include file="includes/header.jspf" %>

<section class="auth">
  <div class="auth-box">
    <h1>Log in</h1>
    <p class="sub">Welcome back. Enter your details to continue exploring.</p>

    <%-- Point this at your login servlet (for example @WebServlet("/login")) --%>
    <form action="${pageContext.request.contextPath}/login" method="post">
      <div class="field">
        <label for="email">Email</label>
        <input type="email" id="email" name="email" autocomplete="email" required>
      </div>
      <div class="field">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" autocomplete="current-password" required>
      </div>
      <button type="submit" class="btn btn-primary">Log in</button>
    </form>

    <p class="auth-switch">
      New here? <a href="${pageContext.request.contextPath}/register.jsp">Create an account</a>
    </p>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
