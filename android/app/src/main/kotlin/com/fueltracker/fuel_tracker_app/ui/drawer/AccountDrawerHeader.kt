package com.fueltracker.fuel_tracker_app.ui.drawer

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val PrimaryBlue = Color(0xFF0066CC)
private val TextPrimary = Color(0xFF333333)
private val TextSecondary = Color(0xFF64748B)

@Composable
fun AccountDrawerHeader(
    name: String,
    email: String,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier) {
        Surface(
            modifier = Modifier.size(64.dp),
            shape = CircleShape,
            color = PrimaryBlue.copy(alpha = 0.12f),
        ) {
            Icon(
                imageVector = Icons.Default.Person,
                contentDescription = null,
                tint = PrimaryBlue,
                modifier = Modifier
                    .size(64.dp)
                    .padding(16.dp),
            )
        }
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = name,
            fontSize = 17.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary,
            lineHeight = 22.sp,
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = email,
            fontSize = 14.sp,
            fontWeight = FontWeight.Normal,
            color = TextSecondary,
            lineHeight = 19.sp,
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun AccountDrawerHeaderPreview() {
    MaterialTheme {
        AccountDrawerHeader(
            name = "Nguyễn Văn A",
            email = "nguyenvana@email.com",
        )
    }
}
