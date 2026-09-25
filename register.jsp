<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String pageTitle = "Create account | ResearchMatch"; %>
<%@ include file="includes/header.jspf" %>

<section class="auth">
  <div class="auth-box">
    <h1>Create account</h1>
    <p class="sub">Set up your profile to start exploring</p>

    <%-- Point this at your registration servlet (for example @WebServlet("/register")) --%>
    <form action="${pageContext.request.contextPath}/register" method="post">
      <div class="field">
        <label for="name">Full name</label>
        <input type="text" id="name" name="name" autocomplete="name" required>
      </div>
      <div class="field">
        <label for="email">Email</label>
        <input type="email" id="email" name="email" autocomplete="email" required>
      </div>
      <div class="field">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" autocomplete="new-password" minlength="8" required>
        <span class="hint">Use at least 8 characters.</span>
      </div>
      
      <div class="field">
        <label>I am a...</label>

        <div class="role-options">
          <label>
            <input
              type="radio"
              name="role"
              value="student"
              required
            >
            Student
          </label>

          <label>
            <input
              type="radio"
              name="role"
              value="researcher"
              required
            >
            Researcher
          </label>
        </div>
      </div>

      <button type="submit" class="btn btn-primary">Create account</button>
    </form>

    <p class="auth-switch">
      Already have an account? <a href="${pageContext.request.contextPath}/login.jsp">Log in</a>
    </p>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
