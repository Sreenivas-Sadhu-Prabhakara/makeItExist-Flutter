package makeitexist;

import com.intuit.karate.junit5.Karate;

class KarateRunner {

    @Karate.Test
    Karate testAll() {
        return Karate.run("classpath:makeitexist").relativeTo(getClass());
    }

    @Karate.Test
    Karate testHealth() {
        return Karate.run("classpath:makeitexist/health").relativeTo(getClass());
    }

    @Karate.Test
    Karate testAuth() {
        return Karate.run("classpath:makeitexist/auth").relativeTo(getClass());
    }

    @Karate.Test
    Karate testRequests() {
        return Karate.run("classpath:makeitexist/requests").relativeTo(getClass());
    }

    @Karate.Test
    Karate testSchedule() {
        return Karate.run("classpath:makeitexist/schedule").relativeTo(getClass());
    }

    @Karate.Test
    Karate testAdmin() {
        return Karate.run("classpath:makeitexist/admin").relativeTo(getClass());
    }
}
